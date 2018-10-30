import javax.swing.JPanel;
import javax.swing.JTextField;

import java.awt.Color;
import java.awt.Component;
import java.awt.Image;

import javax.swing.JLabel;
import java.awt.Font;
import java.awt.Graphics;

import javax.swing.*;
import javax.swing.GroupLayout.Alignment;
import javax.swing.LayoutStyle.ComponentPlacement;
import java.awt.event.ActionListener;
import java.awt.event.AdjustmentEvent;
import java.awt.event.AdjustmentListener;
import java.io.IOException;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.awt.event.ActionEvent;
import java.awt.ScrollPane;
import java.awt.SystemColor;
import com.jgoodies.forms.factories.DefaultComponentFactory;

public class CardioPanel extends JPanel {
	private BlueSliderComm bsc;
	private BlueStepMotBeltComm bsmbc;
	private JButton left, right, up, down, stop, startAcquire, acquisitionProtocol, setSpeed, setStep;
	private JLabel AdjustSlider, AdjustPump, bluetoothEnabled, Cardiovate, DateTime, humidity, temp, Timer;
	private JScrollBar speedScroll, stepScroll,timerScroll;
	private JSeparator separator, separator_1;
	private JTextField speedText, stepText;
	private Image img;
	private Thread timerClock, dateClock, DHT11Clock;
	private int second = 0, minute = 1;
	private Boolean stopThread = false, startThreadOnce = false;

	@SuppressWarnings("unchecked")
	public CardioPanel() throws IOException {
		// Initialize Bluetooth Communication objects
		bsc = new BlueSliderComm();
		bsmbc = new BlueStepMotBeltComm();
		
		// Initialize JLabel with Cardiovate logo
		Cardiovate = new JLabel("");
		img = new ImageIcon(this.getClass().getResource("cardiovate.png")).getImage();
		Cardiovate.setIcon(new ImageIcon(img));

		// Initialize JLabels for GUI
		AdjustSlider = new JLabel("Adjust Slider");
		AdjustPump = new JLabel("Adjust Pump");
		DateTime = new JLabel("Date: 00/00/0000       Time: 00:00:00");
		Timer = new JLabel("Timer 1:00");
		humidity = new JLabel("Humidity: ");
		temp = new JLabel("Temperature: ");
		bluetoothEnabled = new JLabel("Bluetooth Enabled");

		// Initialize JButtons for GUI
		startAcquire = new JButton("Start Acquisition");
		setSpeed = new JButton("Set Speed");
		setStep = new JButton("Set Step Size");
		left = new JButton("Left");
		right = new JButton("Right");
		up = new JButton("Up");
		down = new JButton("Down");
		stop = new JButton("Stop");
		acquisitionProtocol = new JButton("Acquisition Protocol");

		// Initialize JTextFields for displaying the values
		// for speed and step size of the slider stepper motor
		speedText = new JTextField("100");
		stepText = new JTextField("300");

		// Initialize the scroll bars for the speed, step, and timer textfields
		speedScroll = new JScrollBar();
		speedScroll.setOrientation(JScrollBar.HORIZONTAL);
		stepScroll = new JScrollBar();
		stepScroll.setOrientation(JScrollBar.HORIZONTAL);
		timerScroll = new JScrollBar();
		timerScroll.setOrientation(JScrollBar.HORIZONTAL);

		// Separators for separating the various modules of control
		separator = new JSeparator();
		separator_1 = new JSeparator();

		showPanel(); // Where the rest of the GUI is configured
		currentDate(); // Start the currentDate function for displaying current
						// date and time
		timerLabel(); // Start the thread for the timer
		DHT11thread(); // Start the thread for recording the humidity and
						// temperature in the electrospinner container
		DHT11Clock.start(); // Start the DHT11 thread for acquiring the humidity
							// and temperature within the electro-spinner's
							// container
	}

	private void showPanel() {
		// Set GUI Background to white
		setBackground(Color.WHITE);

		// Set GUI texts to dark blue color
		AdjustPump.setForeground(new Color(0, 0, 139));
		AdjustSlider.setForeground(new Color(0, 0, 139));
		bluetoothEnabled.setForeground(Color.GREEN);
		DateTime.setForeground(new Color(0, 0, 139));
		humidity.setForeground(new Color(0, 0, 139));
		temp.setForeground(new Color(0, 0, 139));
		Timer.setForeground(new Color(0, 0, 139));

		// Set the fonts of various GUIs
		AdjustSlider.setFont(new Font("Times New Roman", Font.BOLD, 30));
		AdjustPump.setFont(new Font("Times New Roman", Font.BOLD, 30));
		left.setFont(new Font("Times New Roman", Font.BOLD, 30));
		right.setFont(new Font("Times New Roman", Font.BOLD, 30));
		up.setFont(new Font("Times New Roman", Font.BOLD, 30));
		down.setFont(new Font("Times New Roman", Font.BOLD, 30));
		stop.setFont(new Font("Times New Roman", Font.BOLD, 30));
		bluetoothEnabled.setFont(new Font("Times New Roman", Font.BOLD, 24));
		DateTime.setFont(new Font("Times New Roman", Font.BOLD, 20));
		startAcquire.setFont(new Font("Times New Roman", Font.BOLD, 30));
		acquisitionProtocol.setFont(new Font("Times New Roman", Font.BOLD, 30));
		Timer.setFont(new Font("Times New Roman", Font.BOLD, 40));
		temp.setFont(new Font("Times New Roman", Font.BOLD, 20));
		humidity.setFont(new Font("Times New Roman", Font.BOLD, 20));
		setSpeed.setFont(new Font("Times New Roman", Font.BOLD, 30));
		setStep.setFont(new Font("Times New Roman", Font.BOLD, 30));
		speedText.setFont(new Font("Times New Roman", Font.BOLD, 30));
		stepText.setFont(new Font("Times New Roman", Font.BOLD, 30));

		// Set size of textfields
		speedText.setColumns(10);
		stepText.setColumns(10);

		// Set properties and boundaries of speed scroll bar
		speedScroll.setValue(60);
		speedScroll.setMaximum(1001);
		speedScroll.setMinimum(10);
		speedScroll.setUnitIncrement(2);

		// Set properties and boundaries of step scroll bar
		stepScroll.setValue(100);
		stepScroll.setUnitIncrement(2);
		stepScroll.setMinimum(10);
		stepScroll.setMaximum(2050);

		// Set maximum and minimum for timer scroll bar
		timerScroll.setValue(1);
		timerScroll.setUnitIncrement(1);
		timerScroll.setMinimum(1);
		timerScroll.setMaximum(60);
		
		/***************************************************************************************
		 **************************** Slider ACTIONLISTENER COMMANDS ****************************
		 ***************************************************************************************/
		right.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				try {
					bsmbc.sendCommand(3, 0);
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				if(bsmbc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		left.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				try {
					bsmbc.sendCommand(2, 0);
				} catch (IOException e) {
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				if(bsmbc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		setStep.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				// Add 1000 to current step then pass
				int passInt = Integer.parseInt(stepText.getText());
				
				// Set values to be written to text file
				try {
					bsmbc.sendCommand(1, passInt);
				} catch (IOException e1) {
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				// Execute

				if(bsmbc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		stepScroll.addAdjustmentListener(new AdjustmentListener() {
			public void adjustmentValueChanged(AdjustmentEvent e) {
				stepText.setText(Integer.toString(stepScroll.getValue()));
			}
		});

		setSpeed.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				// Get current speed value
				int passInt = Integer.parseInt(speedText.getText());

				try {
					bsmbc.sendCommand(0, passInt);
				} catch (IOException e1) {
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}

				if(bsmbc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		speedScroll.addAdjustmentListener(new AdjustmentListener() {
			public void adjustmentValueChanged(AdjustmentEvent e) {
				speedText.setText(Integer.toString(speedScroll.getValue()));
			}
		});
		/***************************************************************************************
		 ************************ Syringe Pump ACTIONLISTENER COMMANDS *************************
		 ***************************************************************************************/
		up.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				try {
					bsc.sendCommand(0, 0);
				} catch (IOException e1) {
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				
				if(bsc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		down.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				try {
					bsc.sendCommand(1, 0);
				} catch (IOException e) {
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				
				if(bsc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		stop.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				try {
					bsc.sendCommand(2, 0);
				} catch (IOException e) {
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				
				if(bsc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
			}
		});

		/***************************************************************************************
		 **************************** TIMER ACTIONLISTENER COMMANDS ****************************
		 ***************************************************************************************/
		timerScroll.addAdjustmentListener(new AdjustmentListener() {
			public void adjustmentValueChanged(AdjustmentEvent e) {
				Timer.setText("Timer " + Integer.toString(timerScroll.getValue()) + ":00");
				minute = timerScroll.getValue();
			}
		});
		startAcquire.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				// Pass the commands to the Arduino
				try {
					bsc.sendCommand(3, minute);
					bsmbc.sendCommand(4, minute);
				} catch (IOException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
					bluetoothEnabled.setText("Bluetooth Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}
				if(bsc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth Pump Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
				if(bsmbc.checkConnection() == false){
					bluetoothEnabled.setText("Bluetooth S.M. Disabled");
					bluetoothEnabled.setForeground(Color.RED);
				}else{
					bluetoothEnabled.setText("Bluetooth Enabled");
					bluetoothEnabled.setForeground(Color.GREEN);
				}
				// Start the timer countdown
				stopThread = false;
				if (startThreadOnce == false) {
					timerClock.start();
					startThreadOnce = true;
				}
				// Disable buttons for communication with Arduino
				startAcquire.setEnabled(false);
				left.setEnabled(false);
				right.setEnabled(false);
				setSpeed.setEnabled(false);
				setStep.setEnabled(false);
				up.setEnabled(false);
				down.setEnabled(false);
				stop.setEnabled(false);
			}
		});

		/*
		 * Acquisiton Protocol ActionListenr When user presses button, they are
		 * shown a dialog with a list of proper electrospinning etiquette.
		 */
		acquisitionProtocol.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent e) {
				Component frame = null;
				JOptionPane.showMessageDialog(frame,
						"Sample Prep Reminders: \n+ Use shiny side of tin foil\n+ Wrap foil neatly & diagonally\n+ Amount of solution used"
								+ "should ~= 0.5 mL\n+ Step size of pump should be 125R\n+ Set current to 14 microAmps\n+ Revolution voltage is 3V\n"
								+ "+ Run electrospinner for 20 minutes\n+ Wear gloves when handling samples");
			}
		});
		

		GroupLayout groupLayout = new GroupLayout(this);
		groupLayout.setHorizontalGroup(
			groupLayout.createParallelGroup(Alignment.LEADING)
				.addGroup(groupLayout.createSequentialGroup()
					.addContainerGap()
					.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
						.addGroup(groupLayout.createSequentialGroup()
							.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
								.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
									.addGroup(groupLayout.createSequentialGroup()
										.addComponent(DateTime)
										.addPreferredGap(ComponentPlacement.RELATED, 368, Short.MAX_VALUE)
										.addComponent(bluetoothEnabled, GroupLayout.PREFERRED_SIZE, 261, GroupLayout.PREFERRED_SIZE)
										.addGap(216))
									.addGroup(groupLayout.createSequentialGroup()
										.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
											.addGroup(groupLayout.createSequentialGroup()
												.addComponent(AdjustPump)
												.addPreferredGap(ComponentPlacement.RELATED, GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
												.addComponent(up, GroupLayout.PREFERRED_SIZE, 144, GroupLayout.PREFERRED_SIZE))
											.addGroup(groupLayout.createSequentialGroup()
												.addGap(1)
												.addGroup(groupLayout.createParallelGroup(Alignment.LEADING, false)
													.addComponent(temp, GroupLayout.DEFAULT_SIZE, 218, Short.MAX_VALUE)
													.addComponent(humidity, GroupLayout.DEFAULT_SIZE, GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)))
											.addGroup(groupLayout.createSequentialGroup()
												.addGap(11)
												.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
													.addGroup(groupLayout.createSequentialGroup()
														.addPreferredGap(ComponentPlacement.RELATED)
														.addComponent(setSpeed, GroupLayout.PREFERRED_SIZE, 205, GroupLayout.PREFERRED_SIZE)
														.addPreferredGap(ComponentPlacement.UNRELATED)
														.addComponent(speedText, GroupLayout.DEFAULT_SIZE, 92, Short.MAX_VALUE))
													.addComponent(speedScroll, GroupLayout.DEFAULT_SIZE, 307, Short.MAX_VALUE))))
										.addGap(18)
										.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
											.addGroup(groupLayout.createSequentialGroup()
												.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
													.addComponent(Cardiovate, GroupLayout.PREFERRED_SIZE, 493, GroupLayout.PREFERRED_SIZE)
													.addGroup(groupLayout.createSequentialGroup()
														.addGroup(groupLayout.createParallelGroup(Alignment.LEADING, false)
															.addGroup(groupLayout.createSequentialGroup()
																.addComponent(setStep, GroupLayout.PREFERRED_SIZE, 206, GroupLayout.PREFERRED_SIZE)
																.addPreferredGap(ComponentPlacement.RELATED)
																.addComponent(stepText, GroupLayout.PREFERRED_SIZE, 144, GroupLayout.PREFERRED_SIZE))
															.addGroup(groupLayout.createSequentialGroup()
																.addGap(18)
																.addComponent(down, GroupLayout.PREFERRED_SIZE, 147, GroupLayout.PREFERRED_SIZE)
																.addGap(18)
																.addComponent(stop, GroupLayout.PREFERRED_SIZE, 173, GroupLayout.PREFERRED_SIZE)))
														.addGap(20)
														.addGroup(groupLayout.createParallelGroup(Alignment.TRAILING)
															.addComponent(acquisitionProtocol)
															.addGroup(groupLayout.createSequentialGroup()
																.addComponent(left, GroupLayout.PREFERRED_SIZE, 162, GroupLayout.PREFERRED_SIZE)
																.addPreferredGap(ComponentPlacement.RELATED)
																.addComponent(right, GroupLayout.PREFERRED_SIZE, 136, GroupLayout.PREFERRED_SIZE)))))
												.addGap(137)
												.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
													.addComponent(separator, GroupLayout.PREFERRED_SIZE, 1, GroupLayout.PREFERRED_SIZE)
													.addComponent(separator_1, GroupLayout.PREFERRED_SIZE, 1, GroupLayout.PREFERRED_SIZE)))
											.addComponent(stepScroll, GroupLayout.PREFERRED_SIZE, 356, GroupLayout.PREFERRED_SIZE))))
								.addComponent(AdjustSlider))
							.addGap(273))
						.addGroup(groupLayout.createSequentialGroup()
							.addComponent(startAcquire)
							.addGap(18)
							.addComponent(Timer, GroupLayout.PREFERRED_SIZE, 245, GroupLayout.PREFERRED_SIZE)
							.addPreferredGap(ComponentPlacement.UNRELATED)
							.addComponent(timerScroll, GroupLayout.PREFERRED_SIZE, 307, GroupLayout.PREFERRED_SIZE)))
					.addContainerGap())
		);
		groupLayout.setVerticalGroup(
			groupLayout.createParallelGroup(Alignment.TRAILING)
				.addGroup(groupLayout.createSequentialGroup()
					.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
						.addGroup(groupLayout.createSequentialGroup()
							.addContainerGap()
							.addComponent(Cardiovate, GroupLayout.DEFAULT_SIZE, GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
						.addGroup(groupLayout.createSequentialGroup()
							.addGap(77)
							.addComponent(temp)
							.addGap(7)
							.addComponent(humidity)))
					.addPreferredGap(ComponentPlacement.RELATED)
					.addGroup(groupLayout.createParallelGroup(Alignment.BASELINE)
						.addComponent(DateTime)
						.addComponent(bluetoothEnabled))
					.addGap(45)
					.addComponent(AdjustSlider)
					.addPreferredGap(ComponentPlacement.UNRELATED)
					.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
						.addComponent(setSpeed, GroupLayout.DEFAULT_SIZE, 82, Short.MAX_VALUE)
						.addComponent(speedText, GroupLayout.DEFAULT_SIZE, 82, Short.MAX_VALUE)
						.addComponent(right, Alignment.TRAILING, GroupLayout.DEFAULT_SIZE, 82, Short.MAX_VALUE)
						.addGroup(groupLayout.createParallelGroup(Alignment.BASELINE)
							.addComponent(stepText, GroupLayout.DEFAULT_SIZE, 82, Short.MAX_VALUE)
							.addComponent(left, GroupLayout.DEFAULT_SIZE, 82, Short.MAX_VALUE))
						.addComponent(setStep, GroupLayout.DEFAULT_SIZE, 82, Short.MAX_VALUE))
					.addGap(26)
					.addGroup(groupLayout.createParallelGroup(Alignment.TRAILING, false)
						.addComponent(stepScroll, GroupLayout.DEFAULT_SIZE, GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
						.addComponent(speedScroll, GroupLayout.DEFAULT_SIZE, 76, Short.MAX_VALUE))
					.addGap(18)
					.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
						.addGroup(groupLayout.createParallelGroup(Alignment.BASELINE)
							.addComponent(up, GroupLayout.DEFAULT_SIZE, 69, Short.MAX_VALUE)
							.addComponent(AdjustPump))
						.addGroup(groupLayout.createParallelGroup(Alignment.BASELINE)
							.addComponent(down, GroupLayout.DEFAULT_SIZE, 69, Short.MAX_VALUE)
							.addComponent(stop, GroupLayout.DEFAULT_SIZE, 69, Short.MAX_VALUE)
							.addComponent(acquisitionProtocol)))
					.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
						.addGroup(groupLayout.createSequentialGroup()
							.addPreferredGap(ComponentPlacement.RELATED)
							.addComponent(separator, GroupLayout.PREFERRED_SIZE, GroupLayout.DEFAULT_SIZE, GroupLayout.PREFERRED_SIZE)
							.addGap(21)
							.addGroup(groupLayout.createParallelGroup(Alignment.LEADING)
								.addGroup(groupLayout.createParallelGroup(Alignment.TRAILING)
									.addGroup(groupLayout.createSequentialGroup()
										.addComponent(startAcquire)
										.addGap(71))
									.addComponent(separator_1, GroupLayout.PREFERRED_SIZE, GroupLayout.DEFAULT_SIZE, GroupLayout.PREFERRED_SIZE))
								.addComponent(Timer)))
						.addGroup(groupLayout.createSequentialGroup()
							.addGap(19)
							.addComponent(timerScroll, GroupLayout.PREFERRED_SIZE, 76, GroupLayout.PREFERRED_SIZE)))
					.addContainerGap())
		);
		setLayout(groupLayout);
	}

	/*
	 * currentDate displays the current date and time on the GUI. This function
	 * runs infinitely on a separate thread from the main program.
	 */
	private void currentDate() {
		dateClock = new Thread() {
			public void run() {
				for (;;) {

					Calendar cal = new GregorianCalendar();
					int month = cal.get(Calendar.MONTH);
					int year = cal.get(Calendar.YEAR);
					int day = cal.get(Calendar.DAY_OF_MONTH);

					int second = cal.get(Calendar.SECOND);
					int minute = cal.get(Calendar.MINUTE);
					int hour = cal.get(Calendar.HOUR);
					DateTime.setText("Date: " + (month+1) + "/" + day + "/" + year + "       Time: " + (hour+12) + ":" + minute
							+ ":" + second);
					try {
						sleep(1000);
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
			}
		};
		dateClock.start();
	}

	/*
	 * timerLabel displays the count down of a 20 minute timer. This function
	 * runs infinitely at program start. A system of primitive locks and keys
	 * allows for the display to be reset using the three JButtons 'Start
	 * Acquisition', 'Stop Timer', and 'Reset?'
	 */
	private void timerLabel() {
		timerClock = new Thread() {
			public void run() {
				for (;;) {
					if (stopThread == false) {
						if (second == 0) {
							second = 59;
							minute--;
						} else {
							second--;
						}
						if (minute == 0 && second <= 0) {
							// Insert alarm here
							// Put thread to sleep
							stopThread = true;
							startThreadOnce = false;
							minute = 20;
							second = 0;
							Timer.setText("Timer: " + minute + ":" + second);
							
							// Enable buttons for communication with Arduino
							left.setEnabled(true);
							right.setEnabled(true);
							up.setEnabled(true);
							down.setEnabled(true);
							stop.setEnabled(true);
							setSpeed.setEnabled(true);
							setStep.setEnabled(true);
						}
						Timer.setText("Timer: " + minute + ":" + second);
					}
					try {
						sleep(1000);
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}
			}
		};
	}

	/*
	 * DHT11thread is used to acquire the current humidity and temperature
	 * within the container housing the electro-spinner. Data is collected every
	 * two seconds per hardware constraints of the sensor used. Humidity is
	 * reported as percentage and temperature in degrees Fahrenheit.
	 */
	private void DHT11thread() {
		DHT11 dht11 = new DHT11();

		DHT11Clock = new Thread() {
			public void run() {
				
				for (;;) {
					dht11.readings();
					try {
						Thread.sleep(2000);
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}

					double humid = dht11.getHumidiy();
					double temperature = dht11.getTemperature();

					humidity.setText("Humidity: " + humid + "%");
					temp.setText("Temperature: " + temperature + "\u00b0" + "F");

					// Check if humidity is around threshold of 50% +/- 5%
					if (humid > 55 || humid < 45) {
						humidity.setForeground(new Color(255, 0, 0));
						startAcquire.setEnabled(false);
					} else {
						if(startThreadOnce == false){
							humidity.setForeground(new Color(0, 0, 139));
							startAcquire.setEnabled(true);
						}
					}
				}
			}
		};
	}
}
