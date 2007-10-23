import org.eclipse.swt
import org.eclipse.swt.widgets

display = Display()
shell = Shell(display)
shell.setText("Hello!")
shell.setSize(200, 200)
shell.open()

while not shell.isDisposed():
	if not display.readAndDispatch():
		display.sleep()
		
display.dispose()