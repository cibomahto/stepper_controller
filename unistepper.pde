
// _Simple_ half-stepping driver for some unipolar stepper motors
// 
// Written by Matt Mets in 2010
//
// Generates a waveform that looks like this:
//
//    ________
// A |        |_______________
//   
//          ________
// B ______|        |_________
//   
//                ________  
// C ____________|        |___
//   
//   ___                ______  
// D    |______________|     
//    1  2  3  4  5  6  7  8

#define FORWARD 1
#define REVERSE 0

// Digital I/O pins to which the n-channel FET drivers are connected
unsigned char motorPins[][4] = {{10, 12, 13, 11},
                                {6, 8, 9, 7},
                                {2, 4, 5, 3}};

// attempt at tracking the absolute position of the head (open loop), in steps
long absPosition[] = {0,0,0};

void setup() {
  // Set all the pins to outputs, and turn them off.  
  for (unsigned char i = 0; i < 4; i++) {
    pinMode(motorPins[0][i], OUTPUT);
    digitalWrite(motorPins[0][i], LOW);
    
    pinMode(motorPins[1][i], OUTPUT);
    digitalWrite(motorPins[1][i], LOW);

    pinMode(motorPins[2][i], OUTPUT);
    digitalWrite(motorPins[2][i], LOW);
  }
  
  Serial.begin(9600);
}

// state machine for the half-stepper
unsigned char states[] = {0,0,0};

// When transitioning from state x to state x+1, turn ouput changeMachine[x] on if x%2 == 0, otherwise off.
static unsigned char changeMachine[] = {3, 1, 0, 2, 1, 3, 2, 0};

void step(unsigned char axis, unsigned char dir) { 
  if (axis > 2) return;
  
  unsigned char pinToChange = 0;
  unsigned char newPinValue = 0;
  
  if (dir == FORWARD) {
    pinToChange = changeMachine[states[axis]];
    newPinValue = states[axis] % 2;
 
    states[axis] = (states[axis] + 1) % 8;
  }
  else {
    pinToChange = changeMachine[(states[axis] + 7) % 8];
    newPinValue = states[axis] % 2;
    
   states[axis] = (states[axis] + 7) % 8;
  }

  digitalWrite( motorPins[axis][pinToChange], newPinValue);
} 
    

// number of times the complete cycle is repeated
#define rotations 100

// microsecond delay between half-steps
#define delayLength 6000


void moveRelative( int X, int Y, int Z ) {  
  if (X > 0) {
    for (int i = 0; i < abs(X); i++) {
      step(0, FORWARD);
      delayMicroseconds(delayLength);
    }  
  }
  if (X < 0) {
    for (int i = 0; i < abs(X); i++) {
      step(0, REVERSE);
      delayMicroseconds(delayLength);
    }  
  }  

  if (Y > 0) {
    for (int i = 0; i < abs(Y); i++) {
      step(1, FORWARD);
      delayMicroseconds(delayLength);
    }  
  }
  if (Y < 0) {
    for (int i = 0; i < abs(Y); i++) {
      step(1, REVERSE);
      delayMicroseconds(delayLength);
    }  
  }
  
  if (Z > 0) {
    for (int i = 0; i < abs(Z); i++) {
      step(2, FORWARD);
      delayMicroseconds(delayLength);
    }  
  }
  if (Z < 0) {
    for (int i = 0; i < abs(Z); i++) {
      step(2, REVERSE);
      delayMicroseconds(delayLength);
    }  
  }  
  
  absPosition[0] += X;
  absPosition[1] += Y;
  absPosition[2] += Z;
}
  

#define penDown moveRelative(0,0,-30)
#define penUp moveRelative(0,0,30)

void loop() {
  
  delay(5000);
  penUp;

  for (int j = 0; j < 7; j++) {
    for (int i = 0; i < 7; i++) {
      penDown;
      moveRelative(40, 0, 0);
      moveRelative(0, 80, 0);
      moveRelative(-40, 0, 0);
      moveRelative(0, -80, 0);

      penUp;
      moveRelative(10,20,0);
   
      penDown;
      moveRelative(20, 0, 0);
      moveRelative(0, 40, 0);
      moveRelative(-20, 0, 0);
      moveRelative(0, -40, 0);

      penUp;
      moveRelative(-10,-20,0);
   
      moveRelative(60, 0, 0);
    }
    moveRelative(-420, 60, 0);
  }
   
   while(true) {}
}

