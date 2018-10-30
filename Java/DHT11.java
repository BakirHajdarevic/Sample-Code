import java.io.*;

public class DHT11 {
	private double lastTemp, lastHum;
	private String LIB_NOT_PRESENT_MESSAGE = "Python: File is missing.";
	private String ERROR_READING = "Failed to get reading. Try again!";
	private String ERROR_READING_MSG = "Python: Failed to get reading. Try again!";
	private String cmd = "sudo python /home/pi/Adafruit_Python_DHT/examples/DHT11_read.py";
	private boolean state = false;
	
	public DHT11() {
		lastTemp = 0.0;
		lastHum = 0.0;
	}

	public void readings() {
		
		try {
			String ret = "";
			try {
				String line;
				Process p = Runtime.getRuntime().exec(cmd.split(" "));
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
			if (ret.length() == 0) // Library is not present
				throw new RuntimeException(LIB_NOT_PRESENT_MESSAGE);
			else {
				// Error reading the the sensor, maybe is not connected.
				if (ret.contains(ERROR_READING)) {
					String msg = String.format(ERROR_READING_MSG, toString());
					throw new Exception(msg);
				} else {
					// Read completed. Parse and update the values
					String[] vals = ret.split("  ");
					double t = Float.parseFloat(vals[0].trim());
					double h = Float.parseFloat(vals[1].trim());
					lastTemp = t;
					lastHum = h;
				}
			}
		} catch (Exception e) {
			//System.out.println(e.getMessage());
			//if (e instanceof RuntimeException)
				//System.exit(-1);
		}
	}

	public double getTemperature() {
		return lastTemp;
	}

	public double getHumidiy() {
		return lastHum;
	}
}
