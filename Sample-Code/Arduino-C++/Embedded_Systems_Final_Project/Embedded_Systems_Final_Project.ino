/*******************************************************************************
 * Project:         CPR Training Module - Embedded Systems Final Project      *
 * Programmers:     Bakir Hajdarevic and Ben Jacobs                           *
 *                                                                            *
 * Institution:     University of Iowa College of Engineering                 *
 * Instructor:      Anton Kruger Ph.D.                                        *
 * Class:           Embedded Systems and Systems Software (ECE:3360)          *
 *                                                                            *
 * Purpose:         This program was designed in the hopes of acting as       *
 *                    a supplementary tool to assist health and safety        *
 *                    educators in teaching effective CPR techniques          *
 *                    while simulataneously creating a fun, game-like         *
 *                    interface that encourages users to actively focus on    *
 *                    correctly administering CPR.                            *
 *                                                                            *
 * Peripherals:     3 - Signals from Force Pressure Pads:                     *
 *                        - Compressions                                      *
 *                        - Airways                                           *
 *                        - Breathing                                         *
 *                  1 - 16x2 LCD Screen                                       *
 *                  1 - Pushbutton (Used With Interrupt)                      *
 *                  1 - 9V Battery Power Supply (With Power Switch)           *
 *                  3 - LEDs                                                  *
 *                                                                            *
 * Description:     The module begins by asking the user to press the         *
 *                    button to begin. After the button is pressed, the       *
 *                    LCD prompts the user to begin compressions. As soon     *
 *                    as the first compression is administered, a timer       *
 *                    begins. After 30 compressions, the timer is clocked     *
 *                    and duration of the compression cycle is calculated.    *
 *                                                                            *
 *                  The LCD then prompts the user to begin ventilations.      *
 *                    As soon as the head is tilted into its proper           *
 *                    position, the ventilation cycle is FINISH THIS!!!!
 *                                                                            *
 *                  After the ventilation cycle is finished, the LCD          *
 *                    calculates and displays the user's score and asks       *
 *                    them to press the button to reset the program.          *
********************************************************************************/

#include <LiquidCrystal.h>                                              // Includes LCD functions.

const int ventilation_pin = A0;                                         // Declares pin used to monitor ventilation.
const int compression_pin = A1;                                         // Declares pin used to monitor compression.
const int head_tilt_pin = A2;                                           // Declares pin used to monitor head tilt.
const int button_interrupt_pin = 0;                                     // Declares pin used for button interrup (actually on pin 2).
const int green_led = 8;
const int red_led = 9;
const int blue_led = 10;
const int LCD_d7_pin = 4;                                               // Declares d7 pin for LCD.
const int LCD_d6_pin = 5;                                               // Declares d6 pin for LCD.
const int LCD_d5_pin = 6;                                               // Declares d5 pin for LCD.
const int LCD_d4_pin = 7;                                               // Declares d4 pin for LCD.
const int LCD_register_select_pin = 13;                                 // Declares RS pin for LCD.
const int LCD_enable_pin = 12;                                          // Declares E pin for LCD.
const int display_delay = 2000;                                         // Declares length of delay for LCD to display information.
const int display_delay_with_check = 500;                               // Declares length of delay for LCD to display information while checking for a signal.
const int compressions_per_cycle = 30;                                  // Declares number of compressions in one round of CPR.
const int ventilations_per_cycle = 2;                                   // Declares number of ventilations in one round of CPR.
const int correct_compressions_per_min = 100;                           // Declares given rate of CPR compressions.
const float compression_threshold = 4.00;                               // Declares the compression force pad threshold value.
const float head_tilt_threshold = 4.50;                                 // Declares the head tilt force pad threshold value.
const float ventilation_threshold = 0;                               // Declares the head tilt force pad threshold value.
int num_cycles = 0;

LiquidCrystal lcd(LCD_register_select_pin,LCD_enable_pin,               // Creates LCD object.
                  LCD_d4_pin,LCD_d5_pin,LCD_d6_pin,LCD_d7_pin);         // Creates LCD object.

volatile boolean begin_program = false;                                 // Boolean to determine if program should begin.

long debouncing_time = 500;                                             // Interrupt Switch Debouncing Code Retrieved From:
volatile unsigned long last_micros;                                     //    http://www.instructables.com/id/Arduino-Software-debouncing-in-interrupt-function/

void button_interrupt()
{
  if((long)(micros() - last_micros) >= debouncing_time * 1000)          // Switches boolean depending if user is beginning or ending program.
  {
    if(begin_program)
    {
      begin_program = false;
    }
    else
    {
      begin_program = true;
    }
    last_micros = micros();
  }
}

void setup()
{
  // Pin Assignments

  attachInterrupt(button_interrupt_pin, button_interrupt, HIGH);        // Creation of button interrupt.

  pinMode(green_led, OUTPUT);
  pinMode(red_led, OUTPUT);
  pinMode(blue_led, OUTPUT);

  digitalWrite(green_led, HIGH);
  digitalWrite(red_led, HIGH);
  digitalWrite(blue_led, HIGH);
  
  Serial.begin(9600);                                                   // Start serial at 9600 baud.
  
  lcd.begin(16,2);                                                      // Initialize LCD.
  lcd.setCursor(3,0);                                                   // Print welcome message.
  lcd.print("Welcome To");                                              // Print welcome message.
  lcd.setCursor(2,1);                                                   // Print welcome message.]
  lcd.print("CPR Training");                                            // Print welcome message.
}

void loop()
{
  lcd.clear();                                                          // Clears previous message on LCD.
  lcd.setCursor(2,0);                                                   // Print welcome message.
  lcd.print("Press Button");                                            // Print welcome message.
  lcd.setCursor(4,1);                                                   // Print welcome message.
  lcd.print("To Start");                                                // Print welcome message.

  int i = 0;
  for(i = 0; i < 4; i++)                                                // Small delay and check for button press.
  {
    if(begin_program)
    {
      program();
    }
    delay(display_delay_with_check);
  }

  lcd.clear();                                                          // Clears previous message on LCD.
  lcd.setCursor(3,0);                                                   // Print welcome message.
  lcd.print("Welcome To");                                              // Print welcome message.
  lcd.setCursor(2,1);                                                   // Print welcome message.
  lcd.print("CPR Training");                                            // Print welcome message.

  i = 0;
  for(i = 0; i < 4; i++)                                                // Small delay and check for button press.
  {
    if(begin_program)
    {
      program();
    }
    delay(display_delay_with_check);
  }
}

void program()
{
  int cpr_cycles = 0;                                                   // Optional: Cycles of CPR desired.
  
  lcd.clear();                                                          // Clears previous message on LCD.
  lcd.setCursor(5,0);                                                   // Prompt user to begin compressions.
  lcd.print("Begin");                                                   // Prompt user to begin compressions.
  lcd.setCursor(2,1);                                                   // Prompt user to begin compressions.
  lcd.print("Compressions");                                            // Prompt user to begin compressions.
  int compression_sensor = analogRead(compression_pin);                 // Reads ADC value from compression pressure pad.
  float compression_value = compression_sensor * (5.0 / 1023.0);        // Converts ADC value to voltage value.
  while(compression_value < compression_threshold)                      // Waits for first compression to start measuring.
  {
    compression_sensor = analogRead(compression_pin);
    compression_value = compression_sensor * (5.0 / 1023.0);
  }
  lcd.clear();                                                          // Clears previous message on LCD.
  float compression_time = compressions();                              // Measures compression portion of CPR.

  lcd.setCursor(5,0);                                                   // Prompt user to begin ventilations.
  lcd.print("Begin");                                                   // Prompt user to begin ventilations.
  lcd.setCursor(2,1);                                                   // Prompt user to begin ventilations.
  lcd.print("Ventilation");                                             // Prompt user to begin ventilations.
  int head_tilt_sensor = analogRead(head_tilt_pin);                     // Reads ADC value from head tilt pressure pad.
  float head_tilt_value = head_tilt_sensor * (5.0 / 1023.0);            // Converts ADC value to voltage value.
  while(head_tilt_value < head_tilt_threshold)                          // Waits for first compression to start measuring.
  {
    head_tilt_sensor = analogRead(head_tilt_pin);
    head_tilt_value = head_tilt_sensor * (5.0 / 1023.0);
  }
  lcd.clear();                                                          // Clears previous message on LCD.
  float head_tilt_time = head_tilt();                                   // Measures ventilation portion of CPR.

  float final_score = calculate_score(compression_time, head_tilt_time);// Calculates user's final score.
  
  while(begin_program)                                                  // Wait for user to press button to return to main menu.
  {
    lcd.clear();                                                        // Clears previous message on LCD.
    lcd.setCursor(1,0);                                                 // Prints results to user.
    lcd.print("Training Over");                                         // Prints results to user.
    lcd.setCursor(1,1);                                                 // Prints results to user.
    lcd.print("Score = ");                                              // Prints results to user.
    lcd.print(final_score);                                             // Prints results to user.
    lcd.print("%");                                                     // Prints results to user.

    delay(display_delay);
    
    lcd.clear();                                                        // Clears previous message on LCD.
    lcd.setCursor(2,0);                                                 // Print return message.
    lcd.print("Press Button");                                          // Print return message.
    lcd.setCursor(4,1);                                                 // Print return message.
    lcd.print("To Reset");                                              // Print return message.

    delay(display_delay);
  }
}

float compressions()
{
  digitalWrite(green_led, HIGH);
  digitalWrite(red_led, LOW);
  digitalWrite(blue_led, LOW);
  float start_time = millis();                                          // Clocks when the user starts compressions.
  
  int compression_count = 1;                                            // Stores total number of comperssions.
  
  int compression_sensor = analogRead(compression_pin);                 // Reads ADC value from compression pressure pad.
  float compression_value = compression_sensor * (5.0 / 1023.0);        // Converts ADC value to voltage value.

  while(compression_count < compressions_per_cycle)                     // 30 compression is one round of CPR compressions.
  {
    compression_sensor = analogRead(compression_pin);
    compression_value = compression_sensor * (5.0 / 1023.0);
    if(compression_value > compression_threshold)                       // Adds one to the total compression count every time a compression is detected.
    {
      compression_count++;
      delay(400);
    }
  }

  float end_time = millis();                                            // Clocks when user finishes compressions.

  float compression_time = (end_time - start_time) / 1000;              // Stores the time duration of compression portion of CPR.

  return compression_time;                                              // Returns the time of one round of CPR compressions.
}

float head_tilt()
{
  int ventilation_count = 0;
  digitalWrite(green_led, LOW);
  digitalWrite(red_led, HIGH);
  digitalWrite(blue_led, LOW);
  
  while(ventilation_count < ventilations_per_cycle)
  {
    int ventilation_sensor = analogRead(ventilation_pin);                 // Reads ADC value from ventilation pressure pad.
    int head_tilt_sensor = analogRead(head_tilt_pin);                     // Reads ADC value from compression pressure pad.
    float ventilation_value = ventilation_sensor * (5.0 / 1023.0);        // Converts ADC value to voltage value.
    float head_tilt_value = head_tilt_sensor * (5.0 / 1023.0);            // Converts ADC value to voltage value.

    if(ventilation_value == ventilation_threshold)
    {
      ventilation_count++;
      digitalWrite(blue_led, HIGH);
      delay(2000);
    }
    digitalWrite(blue_led, LOW);
  }
  
  return 0;
}

float calculate_score(float compression_time, float head_tilt_time)
{
  float compression_rate = 29 / compression_time * 60;                  // Finds user's compressions/min.
  float compression_score = 100 - (((abs(compression_rate               // Finds percent accuracy to standard 100 compressions/min.
                                   - correct_compressions_per_min))     // Finds percent accuracy to standard 100 compressions/min.
                                   /correct_compressions_per_min)*100); // Finds percent accuracy to standard 100 compressions/min.

  float final_score = compression_score;                                // Calculates final score.

  Serial.println(compression_time);
 
  return final_score;
}

