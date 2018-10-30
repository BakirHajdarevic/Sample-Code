import java.awt.GraphicsConfiguration;
import java.awt.HeadlessException;
import java.io.IOException;

import javax.swing.JFrame;

@SuppressWarnings("serial")
public class CardioFrame extends JFrame {
	private CardioPanel panel;
	
	public CardioFrame() throws IOException{
		panel = new CardioPanel();
		
		setUpGUI();
	}
	
	private void setUpGUI(){
		this.setContentPane(panel);
	}
}