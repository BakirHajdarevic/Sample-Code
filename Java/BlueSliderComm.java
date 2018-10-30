import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;

public class BlueSliderComm {
	private String filePath = "/home/pi/temp/bluetooth.txt";
	private String cmd = "sudo python /home/pi/temp/bluetoothHC06.py";
	private String LIB_NOT_PRESENT_MESSAGE = "Python: File is missing.";
	private String BLUETOOTH_NOT_PRESENT = "Python: Could not find available Bluetooth device.";
	private String BLUETOOTH_SUCCESS = "Python: Passed message";
	private File file;
	private FileWriter fw;
	private BufferedWriter bw;
	private Boolean checkBluetooth = true;
	private String[] commandArray = {"u","d","s","t"};
	private int command = 0,value = 0;
	
	// Constructor
	public BlueSliderComm() throws IOException{
		File file = new File(filePath);
		fw = new FileWriter(file.getAbsoluteFile());
		bw = new BufferedWriter(fw);
	}
	
	public void sendCommand(int command,int value) throws IOException{
		this.command = command;
		this.value = value;
		
		//Write to text file all values
		while(value != 0){
			bw.write(Integer.toString((value%10)));
			value = value/10;
			bw.newLine();
		}
		bw.write(commandArray[command]);
		
		// Execute Python script to read
		runPythonBluetooth();
	}
	
	
	// Run the python script which will read from the text file
	// then communicate to the Arduino.
	private void runPythonBluetooth(){
		try {
			String ret = "";
			try {
				String line;
				Process p = Runtime.getRuntime().exec(cmd);
				BufferedReader input = new BufferedReader(new InputStreamReader(p.getInputStream()));
				p.waitFor();
	            int exitVal = p.waitFor();
	            
				while ((line = input.readLine()) != null) {
					ret += (line + '\n');
				}
				input.close();
			} catch (Exception ex) {
				ex.printStackTrace();
			}
			ret.trim();
			if (ret.length() == 0){
				checkBluetooth = false;
				// Library is not present
				throw new RuntimeException(LIB_NOT_PRESENT_MESSAGE);
			}
			else {
				if(ret.equals(BLUETOOTH_NOT_PRESENT)){
					checkBluetooth = false;
				}else if(ret.equals(BLUETOOTH_SUCCESS)){
					checkBluetooth = true;
				}
			}
		}catch (Exception e) {
			checkBluetooth = false;
		}
	}
	public Boolean checkConnection(){
		return checkBluetooth;
	}

}
