namespace Boojay.Compilation

import System.IO

import Boo.Lang.Compiler
import Boo.Lang.Compiler.Ast
import Boo.Lang.Compiler.Steps
import Boo.Lang.Compiler.TypeSystem

import Boo.Lang.PatternMatching

import org.objectweb.asm
import org.objectweb.asm.Type

class BoojayEmitter(AbstractVisitorCompilerStep):
		
	_classWriter as ClassWriter
	_code as MethodVisitor
	_currentMethod as Method
	_typeMappings as Hash
	_primitiveMappings as Hash
	
	override def Initialize(context as CompilerContext):
		super(context)		
		initializeTypeMappings()

	def Run():
		Visit(CompileUnit)
		
	def initializeTypeMappings():
		_typeMappings = {
			typeSystem.ObjectType: "java/lang/Object",
			typeSystem.StringType: "java/lang/String",
			typeSystem.ICallableType: "Boojay/Runtime/Callable",
			typeSystem.TypeType: "java/lang/Class",
			typeSystem.IEnumerableType: "Boojay/Runtime/Enumerable",
			typeSystem.IEnumeratorType: "Boojay/Runtime/Enumerator",
			typeSystem.RuntimeServicesType: "Boojay/Runtime/RuntimeServices",
			typeSystem.Map(typeof(System.IDisposable)): "Boojay/Runtime/Disposable",
		}
		
		_primitiveMappings = {
			typeSystem.BoolType: BOOLEAN_TYPE.getDescriptor(),
			typeSystem.IntType: INT_TYPE.getDescriptor(),
			typeSystem.VoidType: VOID_TYPE.getDescriptor(),
			typeSystem.CharType: CHAR_TYPE.getDescriptor(),
		}
		
	override def OnInterfaceDefinition(node as InterfaceDefinition):
		emitTypeDefinition node
	
	override def OnClassDefinition(node as ClassDefinition):
		emitTypeDefinition node
		
	def emitTypeDefinition(node as TypeDefinition):
		_classWriter = ClassWriter(ClassWriter.COMPUTE_MAXS)
		_classWriter.visit(
			Opcodes.V1_5,
			typeAttributes(node),
			javaType(node.FullName), 
			null,
			javaType(baseType(node)),
			implementedInterfaces(node))
			
		emit node.Members
		
		_classWriter.visitEnd()
		
		writeClassFile node
		
	def implementedInterfaces(node as TypeDefinition):
		interfaces = array(
				javaType(itf)
				for itf in node.BaseTypes
				if isInterface(itf))
		if len(interfaces) == 0: return null
		return interfaces
		
	def isInterface(typeRef as TypeReference):
		return typeBinding(typeRef).IsInterface
		
	def typeBinding(node as Node) as IType:
		return entity(node)
		
	def expressionType(e as Expression) as IType:
		return self.TypeSystemServices.GetExpressionType(e)
		
	def typeAttributes(node as TypeDefinition):
		attrs = 0
		match node.NodeType:
			case NodeType.ClassDefinition:
				attrs += Opcodes.ACC_SUPER
			case NodeType.InterfaceDefinition:
				attrs += (Opcodes.ACC_INTERFACE + Opcodes.ACC_ABSTRACT)
		if node.IsPublic:
			attrs += Opcodes.ACC_PUBLIC
		return attrs
		
	def writeClassFile(node as TypeDefinition):
		fname = classFullFileName(node)
		ensurePath(fname)
		File.WriteAllBytes(Path.Combine(outputDirectory(), fname), _classWriter.toByteArray())
		
	def outputDirectory():
		return Parameters.OutputAssembly
		
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
				
			case BinaryExpression(
					Operator: BinaryOperatorType.LessThan,
					Left: l,
					Right: r):
				emit l
				emit r
				IF_ICMPLT label
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
		
	override def OnField(node as Field):
		field = _classWriter.visitField(
					memberAttributes(node),
					node.Name,
					typeDescriptor(entity(node.Type)),
					null,
					null)
		field.visitEnd() 
		
	override def OnConstructor(node as Constructor):
		emitMethod "<init>", node
		
	_methodMappings = {
		".ctor": "<init>",
		"constructor": "<init>",
		"Main": "main",
		"ToString": "toString",
		"Equals": "equals",
		"GetType": "getClass"
	}
	
	override def OnMethod(node as Method):
		emitMethod methodName(node.Name), node
		
	def methodName(name as string):
		return _methodMappings[name] or name
		
	def emitMethod(methodName as string, node as Method):
		_code = _classWriter.visitMethod(
					memberAttributes(node),
					methodName,
					javaSignature(node),
					null,
					null)
					
		if not node.IsAbstract:
			_currentMethod = node
			emitMethodBody node
		_code.visitEnd()
		
	def emitMethodBody(node as Method):
		prepareLocalVariables node
		
		_code.visitCode()
		
		emit node.Body		
		RETURN
	
		_code.visitMaxs(0, 0)
		
	def memberAttributes(node as TypeMember):
		attributes = Opcodes.ACC_PUBLIC
		if node.IsStatic: attributes += Opcodes.ACC_STATIC
		if node.IsAbstract: attributes += Opcodes.ACC_ABSTRACT
		return attributes
		
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
		
	def newTemp(type as IType):
		i = nextLocalIndex()
		local = CodeBuilder.DeclareTempLocal(self._currentMethod, type)
		index local.Local, i
		return local
		
	def nextLocalIndex():
		locals = _currentMethod.Locals
		if len(locals) == 0: return firstLocalIndex(_currentMethod)
		return index(entity(locals[-1])) + 1
			
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
		
	override def OnNullLiteralExpression(node as NullLiteralExpression):
		ACONST_NULL
		
	override def OnReturnStatement(node as ReturnStatement):
		if node.Expression is null:
			RETURN
		else:
			emit node.Expression
			if isReferenceType(node.Expression):
				ARETURN
			else:
				IRETURN
				
	def isReferenceType(e as Expression):
		return not expressionType(e).IsValueType
		
	override def OnMethodInvocationExpression(node as MethodInvocationExpression):
		match entity(node.Target):
			case ctor = IConstructor():
				emitConstructorInvocation ctor, node
			case method = IMethod():
				emitMethodInvocation method, node
			case builtin = BuiltinFunction():
				emitBuiltinInvocation builtin, node
				
	def emitSuperMethodInvocation(method as InternalMethod, node as MethodInvocationExpression):
		ALOAD 0
		emit node.Arguments
		INVOKESPECIAL method.Overriden
				
	def emitConstructorInvocation(ctor as IConstructor, node as MethodInvocationExpression):
		match node.Target:
			case SuperLiteralExpression():
				ALOAD 0
				emit node.Arguments
				INVOKESPECIAL ctor
			otherwise:
				emitObjectCreation ctor, node
				
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
		match node.Target:
			case SuperLiteralExpression():
				emitSuperMethodInvocation method, node
			otherwise:
				emitMethodInvocationHandlingSpecialCases method, node
				
	def emitMethodInvocationHandlingSpecialCases(method as IMethod, node as MethodInvocationExpression):
		if isSpecialIkvmGetter(method):
			emitSpecialIkvmGetter(method)
			return
			
		if isArrayLength(method):
			emit node.Target
			ARRAYLENGTH
			return
			
		if handleSpecialStringMethod(method, node):
			return
			
		emitRegularMethodInvocation method, node
		
	def emitRegularMethodInvocation(method as IMethod, node as MethodInvocationExpression):
		emit node.Target
		emit node.Arguments
		
		if method.IsStatic:
			INVOKESTATIC method
		elif method.DeclaringType.IsInterface:
			INVOKEINTERFACE method
		else:
			INVOKEVIRTUAL method 	
			
	def handleSpecialStringMethod(method as IMethod, node as MethodInvocationExpression):
		if method.DeclaringType is not typeSystem.StringType:
			return false
			
		match method.Name:
			case "get_Item":
				emit node.Target
				emit node.Arguments
				invokeWithName Opcodes.INVOKEVIRTUAL, method, "charAt"
			case "get_Length":
				emit node.Target
				invokeWithName Opcodes.INVOKEVIRTUAL, method, "length"
			otherwise:
				return false
				
		return true			
			
	def isArrayLength(method as IMethod):
		return method.FullName == "System.Array.get_Length"
		
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
			
	override def OnRaiseStatement(node as RaiseStatement):
		if node.Exception is not null:
			emit node.Exception
			ATHROW
		else:
			ALOAD index(entity(enclosingHandler(node).Declaration))
			ATHROW
			
	def enclosingHandler(node as Node) as ExceptionHandler:
		return node.GetAncestor(NodeType.ExceptionHandler)
			
	override def OnTryStatement(node as TryStatement):
		L1 = Label()
		L2 = Label()
		L3 = Label()
		mark L1
		emit node.ProtectedBlock
		GOTO L3
		mark L2
		
		for handler in node.ExceptionHandlers:
			L4 = Label()
			mark L4
			decl = handler.Declaration
			TRYCATCHBLOCK L1, L2, L4, javaType(decl.Type)
			ASTORE index(entity(decl))
			emit handler.Block
			GOTO L3
			
		if node.EnsureBlock is null:
			
			mark L3
		
		else:
			
			L4 = Label()
			mark L4
			TRYCATCHBLOCK L1, L4, L4, null
			temp = newTemp(typeSystem.ObjectType)
			ASTORE index(temp)
			emit node.EnsureBlock
			ALOAD index(temp)
			ATHROW
			
			mark L3
			emit node.EnsureBlock
		
	override def OnCastExpression(node as CastExpression):
		emit node.Target
		CHECKCAST javaType(node.Type)
			
	override def OnTryCastExpression(node as TryCastExpression):
		emit node.Target
		DUP
		INSTANCEOF javaType(node.Type)
		L1 = Label()
		L2 = Label()
		IFNE L1
		POP
		ACONST_NULL
		GOTO L2
		mark L1
		CHECKCAST javaType(node.Type)
		mark L2
			
	override def OnBinaryExpression(node as BinaryExpression):
		match node.Operator:
			
			case BinaryOperatorType.Assign:
				emitAssignment node
				
			case BinaryOperatorType.Subtraction:
				emitSubtraction node
			case BinaryOperatorType.Addition:
				emitAddition node
			case BinaryOperatorType.Multiply:
				emitMultiply node
				
			case BinaryOperatorType.TypeTest:
				emitTypeTest node
				
			case BinaryOperatorType.Equality:
				emitEquality node
			case BinaryOperatorType.Inequality:
				emitInequality node
				
			case BinaryOperatorType.ReferenceEquality:
				emitReferenceEquality node
			case BinaryOperatorType.ReferenceInequality:
				emitReferenceInequality node
			
			case BinaryOperatorType.GreaterThanOrEqual:
				emitComparison node, Opcodes.IF_ICMPLT
				
	def emitComparison(node as BinaryExpression, instruction as int):
		L1 = Label()
		L2 = Label()
		
		emit node.Left
		emit node.Right
		emitJumpInsn instruction, L1
		ICONST_1
		GOTO L2
		mark L1
		ICONST_0
		mark L2 
				
	def emitReferenceInequality(node as BinaryExpression):
		emitComparison node, Opcodes.IF_ACMPEQ
	    				
	def emitReferenceEquality(node as BinaryExpression):
		emitComparison node, Opcodes.IF_ACMPNE	
		
	def emitInequality(node as BinaryExpression):
		assert isInteger(node.Left) and isInteger(node.Right)
		emitComparison node, Opcodes.IF_ICMPEQ
	    				
	def emitEquality(node as BinaryExpression):
		assert isInteger(node.Left) and isInteger(node.Right)
		emitComparison node, Opcodes.IF_ICMPNE	
		
	def isInteger(e as Expression):
		return typeSystem.IsIntegerOrBool(expressionType(e))
					
	def emitTypeTest(node as BinaryExpression):
		match node.Right:
			case TypeofExpression(Type: t):
				emit node.Left
				INSTANCEOF javaType(t)
				
				
	def emitMultiply(node as BinaryExpression):
		emit node.Left
		emit node.Right
		IMUL
				
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
                    	emit node.Right
                    	PUTFIELD field
			case reference = ReferenceExpression():
				emit node.Right
				match entity(reference):
					case local = ILocalEntity():
						if not local.Type.IsValueType:
							ASTORE index(local)
						else:
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
				
	override def OnSelfLiteralExpression(node as SelfLiteralExpression):
		ALOAD 0
				
	override def OnReferenceExpression(node as ReferenceExpression):
		match entity(node):
			case param = InternalParameter():
				emitLoad param.Type, param.Index
			case local = ILocalEntity():
				emitLoad local.Type, index(local)
			case type = IType():
				LDC type
				
	def emitLoad(type as IType, index as int):
		if not type.IsValueType:
			ALOAD index
		else:
			ILOAD index
			
	def isChar(type as IType):
		return type == typeSystem.CharType
			
	def isIntegerOrBool(type as IType):
		return typeSystem.IsIntegerOrBool(type)
				
	def stripGetterPrefix(name as string):
		return name[len("get_"):]				
		
	override def OnArrayLiteralExpression(node as ArrayLiteralExpression):
		ICONST len(node.Items)
		ANEWARRAY javaType(expressionType(node).GetElementType())
		i = 0
		for item in node.Items:
			DUP
			ICONST i++
			emit item
			AASTORE
			
	override def OnSlicingExpression(node as SlicingExpression):
		assert 1 == len(node.Indices)
		match node.Indices[0].Begin:
			case IntegerLiteralExpression(Value: value):
				if value < 0:
					emitNormalizedArraySlicing node
				else:
					emitRawArraySlicing node
					
			otherwise:
				emitNormalizedArraySlicing node
				
	def emitRawArraySlicing(node as SlicingExpression):
		emit node.Target
		emit node.Indices[0].Begin
		AALOAD
				
	def emitNormalizedArraySlicing(node as SlicingExpression):
		L1 = Label()
		local = ensureLocal(node.Target)
		ALOAD index(local)
		emit node.Indices[0].Begin
		DUP
		ICONST_0
		IF_ICMPGE L1
		ALOAD index(local)
		ARRAYLENGTH
		IADD
		mark L1
		AALOAD
		
	def ensureLocal(e as Expression):
		local = optionalEntity(e) as InternalLocal
		if local is not null: return local
		
		local = newTemp(expressionType(e))
		emit e
		ASTORE index(local)
		return local
		
	override def OnStringLiteralExpression(node as StringLiteralExpression):
		LDC node.Value
		
	override def OnIntegerLiteralExpression(node as IntegerLiteralExpression):
		ICONST node.Value
		
	override def OnBoolLiteralExpression(node as BoolLiteralExpression):
		if node.Value:
			ICONST_1
		else:
			ICONST_0 
		
	def baseType(node as TypeDefinition):
		if node isa InterfaceDefinition: return TypeSystemServices.ObjectType
		return self.GetType(node).BaseType
		
	typeSystem as JavaTypeSystem:
		get: return self.TypeSystemServices
		
	def javaSignature(method as IMethod):
		return ("("
			+ join(typeDescriptor(p.Type) for p in method.GetParameters(), "")
			+ ")"
			+ typeDescriptor(method.ReturnType))
		
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
		emitLdcInsn value
		
	def LDC(type as IType):
		emitLdcInsn org.objectweb.asm.Type.getType(typeDescriptor(type))
		
	def IFEQ(label as Label):
		emitJumpInsn Opcodes.IFEQ, label
		
	def IF_ACMPEQ(label as Label):
		emitJumpInsn Opcodes.IF_ACMPEQ, label
		
	def IF_ICMPGE(label as Label):
		emitJumpInsn Opcodes.IF_ICMPGE, label
		
	def IF_ICMPGT(label as Label):
		emitJumpInsn Opcodes.IF_ICMPGT, label
		
	def IF_ICMPLE(label as Label):
		emitJumpInsn Opcodes.IF_ICMPLE, label
		
	def IF_ICMPLT(label as Label):
		emitJumpInsn Opcodes.IF_ICMPLT, label
	
	def IFNE(label as Label):
		emitJumpInsn Opcodes.IFNE, label
	
	def IF_ACMPNE(label as Label):
		emitJumpInsn Opcodes.IF_ACMPNE, label
		
	def GOTO(label as Label):
		emitJumpInsn Opcodes.GOTO, label
		
	def INSTANCEOF(typeName as string):
		emitTypeInsn Opcodes.INSTANCEOF, typeName
		
	def CHECKCAST(typeName as string):
		emitTypeInsn Opcodes.CHECKCAST, typeName
	
	def ILOAD(index as int):
		emitVarInsn Opcodes.ILOAD, index
		
	def ICONST(value as int):
		if value >= -1 and value <= 5:
			emitInsn iconstOpcodeFor(value)
		elif value >= -127 and value <= 127:
			emitIntInsn Opcodes.BIPUSH, value
		else:
			emitIntInsn Opcodes.SIPUSH, value
			
	def ICONST_0():
		emitInsn Opcodes.ICONST_0
		
	def ICONST_1():
		emitInsn Opcodes.ICONST_1
		
	def iconstOpcodeFor(value as int):
		if value == 0: return Opcodes.ICONST_0
		if value == 1: return Opcodes.ICONST_1
		if value == 2: return Opcodes.ICONST_2
		if value == 3: return Opcodes.ICONST_3
		if value == 4: return Opcodes.ICONST_4
		if value == 5: return Opcodes.ICONST_5
		if value == -1: return Opcodes.ICONST_M1
		raise System.ArgumentException("value")
	
	def ISTORE(index as int):
		emitVarInsn(Opcodes.ISTORE, index)
		
	def ACONST_NULL():
		emitInsn Opcodes.ACONST_NULL
		
	def ALOAD(index as int):
		emitVarInsn(Opcodes.ALOAD, index)
		
	def ANEWARRAY(type as string):
		emitTypeInsn Opcodes.ANEWARRAY, type
		
	def ARRAYLENGTH():
		emitInsn Opcodes.ARRAYLENGTH
		
	def AASTORE():
		emitInsn Opcodes.AASTORE
		
	def AALOAD():
		emitInsn Opcodes.AALOAD
		
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
		
	def INVOKEINTERFACE(method as IMethod):
		invoke(Opcodes.INVOKEINTERFACE, method)
		
	def TRYCATCHBLOCK(begin as Label, end as Label, target as Label, type as string):
		_code.visitTryCatchBlock(begin, end, target, type)
		
	def ATHROW():
		emitInsn(Opcodes.ATHROW)
		
	def RETURN():
	   emitInsn(Opcodes.RETURN)
		
	def ARETURN():
	   emitInsn(Opcodes.ARETURN)
	   
	def IRETURN():
	   emitInsn(Opcodes.IRETURN)
		
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
		
	def IMUL():
		emitInsn(Opcodes.IMUL)
		
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
		invokeWithName opcode, method, methodName(method.Name)
				
	def invokeWithName(opcode as int, method as IMethod, methodName as string):
		_code.visitMethodInsn(
				opcode,
				javaType(method.DeclaringType),
				methodName,
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
				typeDescriptor(fieldType))
				
	def entity(node as Node):
		return GetEntity(node)
		
	def optionalEntity(node as Node):
		return self.TypeSystemServices.GetOptionalEntity(node)
		
	def javaType(typeRef as TypeReference):
		return javaType(entity(typeRef) as IType)
		
	def typeDescriptor(type as IType) as string:
		if type in _primitiveMappings: return _primitiveMappings[type]
		if type.IsArray: return "[" + typeDescriptor(type.GetElementType())
		return "L" + javaType(type) + ";"
		
	def javaType(type as IType) as string:
		if type in _typeMappings: return _typeMappings[type]
		return javaType(type.FullName)
		
	def javaType(typeName as string):
		return typeName.Replace('.', '/')
		
		