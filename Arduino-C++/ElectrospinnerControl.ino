  /*-----( Import needed libraries )-----*/
#include <SoftwareSerial.h>
#include <TimerFreeTone.h>
#include <SimpleTimer.h>

#define TONE_PIN 13 // Pin you have speaker/piezo connected to

/***********************************************
 *************** GLOBAL VARIABLES **************
 ***********************************************/
 
// Digital Output pins for controlling 
// the pump stepper motor
const int Xpos = 11;
const int Xneg = 10;
const int NXT = 12;

// Digital Output pin for controlling tone
const int tonePin = 13;
 
 // the timer object
SimpleTimer timer;

// Value for timer
double value = 0;

// Place value variable
double place = 0;

// Variables for controlling the tone
int melody[] = { 262, 196, 196, 220, 196, 0, 247, 262 };
int duration[] = { 250, 125, 125, 250, 250, 250, 250, 250 };
int millisec = 1;

void setup() {
  // Initial parameters to be set at boot
  Serial.begin(9600);

  // Configure the output pins to the syringe-pump
  // stepper motor
  pinMode(Xpos, OUTPUT);
  pinMode(Xneg, OUTPUT);
  pinMode(NXT, OUTPUT);
}

void loop() {
  // Check for command from Raspberry Pi
  if ( Serial.available()) {
    // Value sent by Raspberry Pi
    int data = Serial.read();
    
    if(data >= 48 && data <= 57){
      // Increment value which will either be speed or step size
      data = data - 48;
      value += pow((double)data,place);
      place++;
    }else if(data == 117){
      pumpUp();
    }else if(data == 100){
      pumpDown();
    }else if(data == 115){
      pumpStop();
    }else if(data == 116){
      millisec = value*60*1000;
      pumpDown();
      setUpTimer();
      timer.run();
      pumpStop();
      // Reset Conditional Variables
      value = 0;
      place = 0;
    }
  }
}
/*******************************************************
 **************** TIMER ACQUISITION SETUP **************
 *******************************************************/
 void setUpTimer(){
    // Set the timer for the function to be called
    // repeatedly during the electrospinning
   timer.setTimeout(millisec,stopTone);
 }
/***********************************************
 ***** SYRINGE PUMP STEPPER MOTOR COMMANDS *****
 ***********************************************/
// Moves syringe-pump stepper motor 
// downwards until the user opts to stop
void pumpUp(){
  digitalWrite(Xpos,HIGH);
  digitalWrite(Xneg,LOW);
  digitalWrite(NXT, HIGH);
}
// Moves syringe-pump stepper motor 
// upwards until the user opts to stop
void pumpDown(){
  digitalWrite(Xpos,LOW);
  digitalWrite(Xneg,HIGH);
  digitalWrite(NXT, HIGH);
}
// Stops the syringe-pump stepper motor 
// from moving in a direction
// Note: Making the Xpos and Xneg low or high
// will stop the motor from moving. They were
// set low to conserve power.
void pumpStop(){
  digitalWrite(Xpos,LOW);
  digitalWrite(Xneg,LOW);
  digitalWrite(NXT, LOW);
}
/***********************************************
 ***************** TONE COMMANDS ***************
 **********************************************/
 // Plays a tone when the timer on the GUI of
 // the Raspberry Pi has reached the time limit
void stopTone(){
  for (int thisNote = 0; thisNote < 8; thisNote++) { // Loop through the notes in the array.
    TimerFreeTone(TONE_PIN, melody[thisNote], duration[thisNote]); // Play thisNote for duration.
    delay(50); // Short delay between notes.
  }
}
