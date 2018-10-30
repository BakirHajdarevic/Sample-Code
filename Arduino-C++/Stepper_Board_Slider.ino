/*-----( Import needed libraries )-----*/
#include <SimpleTimer.h>
#include <SoftwareSerial.h>
#include <Adafruit_MotorShield.h>
#include <Wire.h>
//#include "utlity/Adafruit_PWMServoDriver.h"

/***********************************************
 *************** GLOBAL VARIABLES **************
 ***********************************************/

// Values for slider-stepper motor
int rpm = 100;
int stepsPerRevolution = 300;

// Create the Adafruit_MotorShield object
Adafruit_MotorShield AFMS = Adafruit_MotorShield();
// Set initial steps per revolution
Adafruit_StepperMotor *myMotor = AFMS.getStepper(stepsPerRevolution,2);
  
// the timer object
SimpleTimer timer;

// IDs of Timers
int timerID1;

// Time for slider acquisition
int timerElectro = 0;

// Time between calls
double sliderInterval = 1.92*stepsPerRevolution;

// Value of speed, step-rate, or timer
double value = 0;

// Place value variable
double place = 0;

void setup() {
  // Initial parameters to be set at boot
  Serial.begin(9600);
  
  // Set the speed (revolution per minute) of the stepper motor
  AFMS.begin();
  myMotor->setSpeed(rpm);
}

void loop() {
  if(Serial.available()){
    int data = Serial.read();
    
    if(data >= 48 && data <= 57){
      // Increment value which will either be speed or step size
      data = data - 48;
      value += pow((double)data,place);
      place++;
    }
    else if(data == 114)
    {// Set steps per revolution
      stepsPerRevolution = value;
      // Reset conditional variables
      value = 0;
      place = 0;
    }
    else if(data == 115){
      // Set speed of slider
      rpm = value;
      myMotor->setSpeed(rpm);
      // Reset conditional variables
      value = 0;
      place = 0;
    }
    else if(data == 116){
      // Set time of acqusiition
      timerElectro = value*60*1000;
      // Start acquisition
      setUpTimer();
      timer.run();
      releaseMotor();
      // Reset conditional variables
      value = 0;
      place = 0;
    }
    else if(data == 76){
      // Move slider left
     stepperMoveLeft(); 
    }else if(data == 82){
     // Move slider right
     stepperMoveRight();   
    }
  }
}
void stepperMoveLeft(){
  myMotor->step(stepsPerRevolution,FORWARD,DOUBLE);
}
void stepperMoveRight(){
  myMotor->step(stepsPerRevolution,BACKWARD,DOUBLE);
}
void sliderAcquisition(){
  stepperMoveLeft();
  delay(sliderInterval);
  stepperMoveRight();
}
void setUpTimer(){
    // Set the timer for the function to be called
    // repeatedly during the electrospinning
    timerID1 = timer.setTimer(sliderInterval, sliderAcquisition, timerElectro);
}
void releaseMotor(){
  myMotor->release();
}

