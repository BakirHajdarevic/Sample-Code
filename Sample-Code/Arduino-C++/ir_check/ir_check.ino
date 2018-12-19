#include <IRremote.h>
#include <IRremoteInt.h>
#include <TimerFreeTone.h>

#define TONE_PIN 13 // Pin you have speaker/piezo connected to

/*-----( Declare IR Remote Constant )-----*/
int receiver = 19;
/*-----( Declare IR Objects)-----*/
IRrecv irrecv(receiver);           // create instance of 'irrecv'
decode_results results;            // create instance of 'decode_results'
// Variables for controlling the tone
int melody[] = { 262, 196, 196, 220, 196, 0, 247, 262 };
int duration[] = { 250, 125, 125, 250, 250, 250, 250, 250 };

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  pinMode(9,OUTPUT);
  // Enable the IR pin
  irrecv.enableIRIn();
  //stopTone();
  ledON();
}

void loop() {
  // put your main code here, to run repeatedly:
  if (irrecv.decode(&results)) // have we received an IR signal?
  {
Serial.println(results.value, HEX);  
//UN Comment to see raw values
    translateIR(); 
    irrecv.resume(); // receive the next value
  }
}
/*-----( Declare User-written Functions )-----*/
void translateIR() // takes action based on IR code received

// describing KEYES Remote IR codes 
{
  //Serial.println(results.value, HEX);
  switch(results.value)
  {  
  // Up Arrow - Increase slider speed by 2
  case 0xFF629D:  ledON(); break;
  // Down Arrow - Decrease slider speed by 2
  case 0xFFA857: ledOFF(); break;
  // Left Arrow - Move slider left
  case 0xFF22DD: stopTone(); break;
  // Right Arrow - Move slider right
  case 0xFFC23D: stopTone(); break;
  // Ok - Start Acquisition
  case 0xFF02FD: stopTone(); break;
  // 1 - Increase slider step by 2
  case 0xFF6897:  stopTone(); break;
  // 2 - Decrease slider step by 2
  case 0xFF9867: stopTone(); break;
  // 3 - Nothing
  case 0xFFB04F: stopTone(); break;
  // 4 - Move syringe pump up continuously
  case 0xFF30CF: stopTone(); break;
  // 5 - Move syringe pump down continuously 
  case 0xFF18E7: stopTone(); break;
  // 6 - Stop syringe pump
  case 0xFF7A85: stopTone(); break;
  // 7 - Nothing
  case 0xFF10EF: stopTone(); break;
  // 8 - Nothing
  case 0xFF38C7: stopTone(); break;
  // 9 - Nothing
  case 0xFF5AA5: stopTone(); break;
  // * - Nothing
  case 0xFF42BD: stopTone(); break;
  // 0 - Nothing
  case 0xFF4AB5: stopTone(); break;
  // # - Set slider speed to default (100) 
  case 0xFF52AD: stopTone(); break;
  // Signal off - Do nothing
  case 0xFFFFFFFF: break;

  default:
    //Serial.println("Nothing happened")
    ;

  }// End Case

} //END translateIR
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
// LED ON
void ledON(){
  digitalWrite(9,HIGH);
}
// LED OFF
void ledOFF(){
  digitalWrite(9,LOW);
}

