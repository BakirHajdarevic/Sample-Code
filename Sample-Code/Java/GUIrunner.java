import java.io.IOException;

import javax.swing.JFrame;

public class GUIrunner {
	
	public static void main(String[] args) throws IOException {
		CardioFrame gui = new CardioFrame();
		gui.setExtendedState(JFrame.MAXIMIZED_BOTH); 
		gui.setVisible(true);
		gui.setResizable(true);
	}
}