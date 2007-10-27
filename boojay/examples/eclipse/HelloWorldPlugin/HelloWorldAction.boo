"""
Hello World eclipse plugin.

A direct translation of
http://www.eclipse.org/articles/Article-Your%20First%20Plug-in/YourFirstPlugin.html
to boo.
"""
namespace HelloWorldPlugin

import org.eclipse.ui
import org.eclipse.jface.action
import org.eclipse.jface.dialogs
import org.eclipse.jface.viewers

class HelloWorldAction(IWorkbenchWindowActionDelegate):

	activeWindow as IWorkbenchWindow

	def run(proxyAction as IAction):
		shell = activeWindow.getShell()
		MessageDialog.openInformation(shell, "Hello from boojay!", "Hello World!")
		
	def init(window as IWorkbenchWindow):
		activeWindow = window
	
	def dispose():
		pass
	
	def selectionChanged(proxyAction as IAction, selection as ISelection):
		pass

	