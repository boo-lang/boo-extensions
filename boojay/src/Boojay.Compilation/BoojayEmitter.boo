namespace Boojay.Compilation

import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem

import Boo.PatternMatching

import org.objectweb.asm
import org.objectweb.asm.Type

class BoojayEmitter(AbstractVisitorCompilerStep):
		
	_classWriter as ClassWriter
	_code as MethodVisitor
	_typeMappings as Hash
	
	override def Initialize(context as CompilerContext):
		super(context)		
		initializeTypeMappings()

	def Run():
		Visit(CompileUnit)
		
	def initializeTypeMappings():
		_typeMappings = {
			typeSystem.ObjectType: "Ljava/lang/Object;",
			typeSystem.StringType: "Ljava/lang/String;",
			typeSystem.BoolType: BOOLEAN_TYPE.getDescriptor(),
			typeSystem.IntType: INT_TYPE.getDescriptor(),
			typeSystem.VoidType: VOID_TYPE.getDescriptor(),
		}
	
	override def EnterClassDefinition(node as ClassDefinition):
		_classWriter = ClassWriter(ClassWriter.COMPUTE_MAXS)
		_classWriter.visit(
			Opcodes.V1_5,
			Opcodes.ACC_PUBLIC + Opcodes.ACC_SUPER,
			node.FullName, 
			null,
			javaName(baseType(node)),
			null)
		return true
		
	override def LeaveClassDefinition(node as ClassDefinition):
		_classWriter.visitEnd()
		
		fname = classFullFileName(node)
		ensurePath(fname)
		File.WriteAllBytes(fname, _classWriter.toByteArray())
		
	override def OnConstructor(node as Constructor):
		pass
		
	override def OnIfStatement(node as IfStatement):
		
		elseLabel = Label()
		afterElseLabel = Label()
		
		emitBranchFalse node.Condition, elseLabel
		emit node.TrueBlock
		if node.FalseBlock is not null:
			GOTO afterElseLabel				
		mark elseLabel
		if node.FalseBlock is not null:		
			emit node.FalseBlock		
			mark afterElseLabel

	def emitBranchFalse(e as Expression, label as Label):
		match e:
			case UnaryExpression(
					Operator: UnaryOperatorType.LogicalNot,
					Operand: condition):
				emitBranchTrue condition, label
			otherwise:
				emit e
				IFEQ label
				
	def emitBranchTrue(e as Expression, label as Label):
		match e:
			case UnaryExpression(
					Operator: UnaryOperatorType.LogicalNot,
					Operand: condition):
				emitBranchFalse condition, label
			otherwise:
				emit e
				IFNE label
	
	override def OnWhileStatement(node as WhileStatement):
		
		testLabel = Label()
		bodyLabel = Label()
		GOTO testLabel
		mark bodyLabel
		emit node.Block
		mark testLabel
		emitBranchTrue node.Condition, bodyLabel
		
	override def OnMethod(node as Method):
		_code = _classWriter.visitMethod(
					Opcodes.ACC_PUBLIC + Opcodes.ACC_STATIC,
					("main" if node.Name == "Main" else node.Name),
					javaSignature(node),
					null,
					null)
					
		prepareLocalVariables node
		
		_code.visitCode()
		
		emit node.Body		
		RETURN
		
		_code.visitMaxs(0, 0)
		_code.visitEnd()
		
	def prepareLocalVariables(node as Method):
		i = firstLocalIndex(node)
		for local in node.Locals:
			index(local, i)
			++i
			
	def firstLocalIndex(node as Method):
		if 0 == len(node.Parameters):
			if node.IsStatic: return 0
			return 1
		return lastParameterIndex(node) + 1
		
	def lastParameterIndex(node as Method):
		param as InternalParameter = entity(node.Parameters[-1])
		return param.Index
			
	def index(node as Local, index as int):
		node["index"] = index
		
	def index(entity as InternalLocal) as int:
		return entity.Local["index"]
		
	override def LeaveExpressionStatement(node as ExpressionStatement):
		discardValueOnStack node.Expression
		
	def discardValueOnStack(node as Expression):
		mie = node as MethodInvocationExpression
		if mie is null: return
		
		m = entity(mie.Target) as IMethod
		if m is null: return
		
		if hasReturnValue(m): POP
		
	def hasReturnValue(m as IMethod):
		return m.ReturnType is not TypeSystemServices.VoidType
		
	override def OnReturnStatement(node as ReturnStatement):
		if node.Expression is null:
			RETURN
		else:
			emit node.Expression
			ARETURN
		
	override def OnMethodInvocationExpression(node as MethodInvocationExpression):
		
		match entity(node.Target):
			case ctor = IConstructor():
				emitObjectCreation ctor, node
			case method = IMethod():
				emitMethodInvocation method, node
			case builtin = BuiltinFunction():
				emitBuiltinInvocation builtin, node
				
	def emitBuiltinInvocation(builtin as BuiltinFunction, node as MethodInvocationExpression):
		match builtin.FunctionType:
			case BuiltinFunctionType.Eval:
				emitEval node
				
	def emitEval(node as MethodInvocationExpression):
		for e in node.Arguments.ToArray()[:-1]:
			emit e
			discardValueOnStack e
		emit node.Arguments[-1]
				
	def emitMethodInvocation(method as IMethod, node as MethodInvocationExpression):
		
		if isSpecialIkvmGetter(method):
			emitSpecialIkvmGetter(method)
			return
		
		emit node.Target
		emit node.Arguments
		
		if method.IsStatic:
			INVOKESTATIC method
		else:
			INVOKEVIRTUAL method 		
		
		
	def emitObjectCreation(ctor as IConstructor, node as MethodInvocationExpression):
		NEW ctor.DeclaringType
		DUP
		emit node.Arguments
		INVOKESPECIAL ctor
				
	def emitSpecialIkvmGetter(method as IMethod):
	"""
	in the ikvm version of GNU.ClassPath the
	console streams are mapped to properties
	where in java they should be treated as static fields
	"""
		emitLoadStaticField(
			method.DeclaringType,
			stripGetterPrefix(method.Name),
			method.ReturnType)
				
	def isSpecialIkvmGetter(method as IMethod):
		return (method.IsStatic
			and method.DeclaringType.FullName == "java.lang.System"
			and method.Name in ("get_out", "get_in", "get_err"))
			
	override def OnBinaryExpression(node as BinaryExpression):
		match node.Operator:
			case BinaryOperatorType.Assign:
				emitAssignment node
			case BinaryOperatorType.Subtraction:
				emitSubtraction node
			case BinaryOperatorType.Addition:
				emitAddition node
				
	def emitAddition(node as BinaryExpression):
		emit node.Left
		emit node.Right
		IADD

	def emitSubtraction(node as BinaryExpression):
		emit node.Left
		emit node.Right
		ISUB
				
	def emitAssignment(node as BinaryExpression):
		match node.Left:
			case memberRef = MemberReferenceExpression():
				match entity(memberRef):
                    case field = IField(IsStatic: false):
                    	emit memberRef.Target
                    	PUTFIELD field
			case reference = ReferenceExpression():
				emit node.Right
				match entity(reference):
					case local = ILocalEntity():
						if not local.Type.IsValueType:
							ASTORE index(local)
						elif isIntegerOrBool(local.Type):
							ISTORE index(local)
						
	
	override def OnMemberReferenceExpression(node as MemberReferenceExpression):
		match entity(node):
			case field = IField(IsStatic: true):
				GETSTATIC field
			case field = IField(IsStatic: false):
				emit node.Target
				GETFIELD field
			case IMethod(IsStatic: false):
				emit node.Target
			case IMethod(IsStatic: true):
				pass
				
	override def OnReferenceExpression(node as ReferenceExpression):
		match entity(node):
			case param = InternalParameter():
				emitLoad param.Type, param.Index
			case local = ILocalEntity():
				emitLoad local.Type, index(local)
				
	def emitLoad(type as IType, index as int):
		if not type.IsValueType:
			ALOAD index
		elif isIntegerOrBool(type):
			ILOAD index
		else:			
			raise "Unsupported type: ${type}"
			
	def isIntegerOrBool(type as IType):
		return self.TypeSystemServices.IsIntegerOrBool(type)
				
	def stripGetterPrefix(name as string):
		return name[len("get_"):]				
		
	override def OnStringLiteralExpression(node as StringLiteralExpression):
		LDC node.Value
		
	override def OnIntegerLiteralExpression(node as IntegerLiteralExpression):
		ICONST node.Value
		
	override def OnBoolLiteralExpression(node as BoolLiteralExpression):
		if node.Value:
			ICONST_1
		else:
			ICONST_0 
		
	def baseType(node as ClassDefinition):
		return self.GetType(node).BaseType
		
	typeSystem as JavaTypeSystem:
		get: return self.TypeSystemServices
		
	def javaSignature(method as IMethod):
		return ("("
			+ join(javaName(p.Type) for p in method.GetParameters(), "")
			+ ")"
			+ javaName(method.ReturnType))
		
	def javaSignature(node as Method):
		return javaSignature(entity(node) as IMethod)
		
	def ensurePath(fname as string):
		path = Path.GetDirectoryName(fname)
		if not string.IsNullOrEmpty(path):
			Directory.CreateDirectory(path)
		
	def classFullFileName(node as TypeDefinition):
		return javaType(entity(node)) + ".class"
		
	def emit(node as Node):
		Visit(node)
		
	def emit(nodes as System.Collections.IEnumerable):
		VisitCollection(nodes)
		
	def LDC(value):
		emitLdcInsn(value)
		
	def IFEQ(label as Label):
		emitJumpInsn(Opcodes.IFEQ, label)
	
	def IFNE(label as Label):
        emitJumpInsn(Opcodes.IFNE, label)

	def GOTO(label as Label):
		emitJumpInsn(Opcodes.GOTO, label)
	
	def ILOAD(index as int):
		emitVarInsn(Opcodes.ILOAD, index)
		
	def ICONST(value as int):
		if value >= -1 and value <= 5:
			emitInsn(iconstOpcodeFor(value))
		elif value >= -127 and value <= 127:
			emitIntInsn Opcodes.BIPUSH, value
		else:
			emitIntInsn Opcodes.SIPUSH, value
			
	def ICONST_0():
		emitInsn(Opcodes.ICONST_0)
		
	def ICONST_1():
		emitInsn(Opcodes.ICONST_1)
		
	def iconstOpcodeFor(value as int):
		if value == 0: return Opcodes.ICONST_0
		if value == 1: return Opcodes.ICONST_1
		if value == 2: return Opcodes.ICONST_2
		if value == -1: return Opcodes.ICONST_M1
		raise System.ArgumentException("value")
	
	def ISTORE(index as int):
		emitVarInsn(Opcodes.ISTORE, index)
		
	def ALOAD(index as int):
		emitVarInsn(Opcodes.ALOAD, index)
		
	def ASTORE(index as int):
		emitVarInsn(Opcodes.ASTORE, index)
		
	def GETSTATIC(field as IField):
		emitLoadStaticField(field.DeclaringType, field.Name, field.Type)
		
	def GETFIELD(field as IField):
		emitField Opcodes.GETFIELD, field
		
	def PUTFIELD(field as IField):
		emitField Opcodes.PUTFIELD, field
		
	def INVOKESTATIC(method as IMethod):
		invoke(Opcodes.INVOKESTATIC, method)
		
	def INVOKEVIRTUAL(method as IMethod):
		invoke(Opcodes.INVOKEVIRTUAL, method)
		
	def INVOKESPECIAL(method as IMethod):
		invoke(Opcodes.INVOKESPECIAL, method)
		
	def RETURN():
	   emitInsn(Opcodes.RETURN)
		
	def ARETURN():
	   emitInsn(Opcodes.ARETURN)
		
	def POP():
		emitInsn(Opcodes.POP)
		
	def NEW(type as IType):
		emitTypeInsn(Opcodes.NEW, javaType(type))
		
	def DUP():
		emitInsn(Opcodes.DUP)
		
	def ISUB():
		emitInsn(Opcodes.ISUB)
		
	def IADD():
		emitInsn(Opcodes.IADD)
		
	def emitVarInsn(opcode as int, index as int):
		_code.visitVarInsn(opcode, index)
		
	def emitInsn(i as int):
		_code.visitInsn(i)
		
	def emitIntInsn(opcode as int, value as int):
		_code.visitIntInsn(opcode, value)
		
	def emitJumpInsn(i as int, label as Label):
		_code.visitJumpInsn(i, label)
		
	def emitLdcInsn(value):
		_code.visitLdcInsn(value)
	
	def emitTypeInsn(opcode as int, name as string):
		_code.visitTypeInsn(opcode, name)
		
	def mark(label as Label):
		_code.visitLabel(label)
		
	def invoke(opcode as int, method as IMethod):
		_code.visitMethodInsn(
				opcode,
				javaType(method.DeclaringType),
				("<init>" if method isa IConstructor else method.Name),
				javaSignature(method))
	
		
	def emitLoadStaticField(declaringType as IType, fieldName as string, fieldType as IType):
		emitField Opcodes.GETSTATIC, declaringType, fieldName, fieldType
		
	def emitField(opcode as int, field as IField):
		emitField opcode, field.DeclaringType, field.Name, field.Type
		
	def emitField(opcode as int, declaringType as IType, fieldName as string, fieldType as IType):
		_code.visitFieldInsn(
				opcode,
				javaType(declaringType),
				fieldName,
				javaName(fieldType))
				
	def entity(node as Node):
		return GetEntity(node)
		
	def javaName(type as IType) as string:
		if type in _typeMappings: return _typeMappings[type]
		if type.IsArray: return "[" + javaName(type.GetElementType())
		return "L" + javaType(type) + ";"
		
	def javaType(type as IType) as string:
		return type.FullName.Replace('.', '/')
		
		