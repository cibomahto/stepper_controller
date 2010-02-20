
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
unsigned char motorPins[][4] = {
  {10, 12, 13, 11},
  {6, 8, 9, 7},
  {2, 4, 5, 3}
};

// attempt at tracking the absolute position of the head (open loop), in steps
long absPosition[] = {0,0,0};

void setup() {
  // Set all the pins to outputs, and turn them off.
  for (unsigned char i = 0; i < 3; i++) {
    for (unsigned char j = 0; j < 4; j++) {
      pinMode(motorPins[i][j], OUTPUT);
      digitalWrite(motorPins[i][j], LOW);
    }
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
#define delayLength 10000


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

// could include <algorithm> instead?
void swap(int& a, int& b) {
  int temp = a;
  a = b;
  b = temp;
}

// Basically just Bresenhams line algorithm, right?
// adapted from Wikipedia: http://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
void moveDiagonal(int X, int Y) {
  // function line(x0, x1, y0, y1)
  
  unsigned char xdir = (X > 0) ? FORWARD : REVERSE;
  unsigned char ydir = (Y > 0) ? FORWARD : REVERSE;
  
  X = abs(X);
  Y = abs(Y);
  
  // boolean steep := abs(y1 - y0) > abs(x1 - x0)
  boolean steep = Y > X;
  
  // if steep then
  //   swap(x0, y0)
  //   swap(x1, y1)
  if (steep) {
    swap(X, Y);
  }
  
  // if x0 > x1 then
  //    swap(x0, x1)
  //    swap(y0, y1)
  
  // int deltax := x1 - x0
  // int deltay := abs(y1 - y0)
  
  // real error := 0
  float error = 0;
  
  // real deltaerr := deltay / deltax
  float deltaerr = (float)Y / (float)X;
 
  // for x from x0 to x1
  for (int x = 0; x < X; x++) {
  //   if steep then plot(y,x) else plot(x,y)
    if (steep) {
      step(1,ydir);
    }
    else {
      step(0,xdir);
    }
    
  //   error := error + deltaerr
    error = error + deltaerr;

  //   if error ≥ 0.5 then
  //     y := y + ystep
  //     error := error - 1.0
    if (error > .5) {
      if (steep) {
        step(0,xdir);
      }
      else {
        step(1,ydir);
      }
      
      
      error = error - 1;
    }
    
    delayMicroseconds(delayLength);
  }
}


// Turn off power to all coils
void deactivateAll() {
  for (unsigned char i = 0; i < 3; i++) {
    for (unsigned char j = 0; j < 4; j++) {
      digitalWrite(motorPins[i][j], LOW);
    }
  }
}


#define penDown moveRelative(0,0,-30)
#define penUp moveRelative(0,0,30)

// square inside of a diamond inside of a square
void patternSqDSq() {
  penDown;
  moveDiagonal(20,0);
  moveDiagonal(0,30);
  moveDiagonal(-20,0);
  moveDiagonal(0,-30);
  penUp;
  
  moveDiagonal(10,0);
  
  penDown;
  moveDiagonal(10,15);
  moveDiagonal(-10,15);
  moveDiagonal(-10,-15);
  moveDiagonal(10,-15);
  penUp;
  
  moveDiagonal(-5,7);
  
  penDown;
  moveDiagonal(10,0);
  moveDiagonal(0,16);
  moveDiagonal(-10,0);
  moveDiagonal(0,-16);  
  penUp;
  
  moveDiagonal(-5,-7);
}

void loop() {
  delay(5000);
  penUp;
  
  //spiral
  penDown;
  int direction = 0;
  int baseLengthX = 5;
  int baseLengthY = 7;
  for (int i = 0; i < 120; i++) {
    int thisLengthX = baseLengthX * (i+2)/2;
    int thisLengthY = baseLengthY * (i+2)/2;
    
    switch(direction)  {
      case 0: moveDiagonal(thisLengthX, 0); break;
      case 1: moveDiagonal(0, thisLengthY); break;
      case 2: moveDiagonal(-thisLengthX, 0); break;
      case 3: moveDiagonal(0, -thisLengthY); break;
    }
    direction = (direction + 1)%4;
  }
  penUp;
  
#if 0
  int i, j;
  for (i = 0; i < 4; i++) {
    for (j = 0; j < 4; j++) {
      patternSqDSq();
      moveDiagonal(40,0);
    }
    moveDiagonal(-40*j, 30);
    
    if (i < 3) {
      moveDiagonal(20,0);

      for (j = 0; j < 3; j++) {
        patternSqDSq();
        moveDiagonal(40,0);
      }
      moveDiagonal(-40*j, 30);
      
      moveDiagonal(-20,0);
    }
  }
#endif

  
#if 0
  for (int j = 0; j < 3; j++) {
    for (int i = 0; i < 3; i++) {
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
    moveRelative(-180, 120, 0);

  }
#endif

  deactivateAll();
  
  while(true) {};
}


