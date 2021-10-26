/////////////////////////add interface elements here

//////////////////////
float batVolt=0.0;
boolean enabled=false;
////////////////////////add variables here
Slider manual1Slider;
Slider manual2Slider;
Slider manual3Slider;
Button modeButton;

float servo1PosTelem;
float servo2PosTelem;

float servo1Val=0;
float servo2Val=0;
float servo3Val=0;

byte mode=0;
byte numModes=2;
String[] modeNames={"indiv", "cartesn"};

float arm1Length=200.0;//pixels
float arm2Length=arm1Length*4.5/6.75;//*3.6/5.5;//measured from prototype

float s1min=-90;
float s1max=90;
float s2min=0;
float s2max=180;

float x=1106;
float y=123;

void setup() {
  size(1500, 800);
  loadWifiSettings();
  rcmdsSetup();
  setupGamepad("Feather 32u4");
  //setup UI here
  //Button(float _xPos, float _yPos, float _size, color _background, color _forground, String _gpButton, int _keyboard, boolean _momentary, boolean _val, String _label)
  //Slider(float _xPos, float _yPos, float _size, float _width, float _low, float _high, color _background, color _stick, String _ga, int _pKey, int _mKey, float _inc, int _tilt, boolean _horizontal, boolean _reverse)
  modeButton=new Button(width*.95, height*.1, width*.09, color(55), color(255), null, 'm', true, false, "mode:        indiv");
  manual1Slider=new Slider(width*.65, height*.65, width*.5, width*.05, s1max, s1min, color(150, 100, 40), color(255), null, 'c', 'z', 0.01, 0, true, false);
  manual2Slider=new Slider(width*.65, height*.8, width*.5, width*.05, s2max, s2min, color(100, 0, 0), color(255), null, 'd', 'a', 0.01, 0, true, false);
  manual3Slider=new Slider(width*.65, height*.95, width*.5, width*.05, 1, -1, color(0, 0, 100), color(255), null, 'e', 'q', 0.02, 0, true, false);
}
void draw() {
  background(0);
  enabled=enableSwitch.run(enabled);
  /////////////////////////////////////add UI here

  modeButton.run();
  if (modeButton.justReleased()) {
    mode++;
    if (mode==numModes) {
      mode=0;
    }
    modeButton.label="mode:        "+modeNames[mode];
  }

  if (mode==0) { //individual axis control
    servo1Val=manual1Slider.run(servo1Val);
    servo2Val=manual2Slider.run(servo2Val);
    if (keyboardCtrl.isPressed('w'))
      servo3Val=0;
    servo3Val=manual3Slider.run(servo3Val);
  }
  if (mode==1) { //cartesian arm control
    pushStyle();
    pushMatrix();
    if (gamepadButton("Button 0", false)||(mousePressed&&mouseX>width*.65-(arm1Length+arm2Length+50)&&mouseX<width*.65+(arm1Length+arm2Length+50)&&mouseY>height/2-(arm1Length+arm2Length+70)&&mouseY<height/2+(70))) {
      float[] angs=new float[3];
      if (gamepadButton("Button 0", false)) {
        x-=gamepadVal("X Axis", 0)*500*(gamepadVal("Y Rotation", .5)+1)/frameRate;
        y+=gamepadVal("Y Axis", 0)*500*(gamepadVal("Y Rotation", .5)+1)/frameRate;
        x=constrain(x, width*.65, width*.65+(arm1Length+arm2Length));
        y=constrain(y, height/2-(arm1Length+arm2Length+70), height/2);
        angs=cartToAngles(x-width*.65, height-height*.6-y, arm1Length, arm2Length);
      } else {
        x=mouseX;
        y=mouseY;
        angs=cartToAngles(mouseX-width*.65, height-height*.6-mouseY, arm1Length, arm2Length);
      }
      angs[0]=degrees(angs[0]);
      angs[1]=degrees(angs[1]);
      if (angs[0]==angs[0]&&angs[1]==angs[1]&&angs[0]>=s1min&&angs[0]<=s1max&&angs[1]>=s2min&&angs[1]<=s2max) {//check
        servo1Val=angs[0];
        servo2Val=angs[1];
      }
    }
    if (keyboardCtrl.isPressed(' ')) { //center
      servo1Val=0;
      servo2Val=0;
    }

    noStroke();
    fill(25);
    rectMode(CORNERS);
    rect(width*.65-(arm1Length+arm2Length+50), height/2-(arm1Length+arm2Length+70), width*.65+(arm1Length+arm2Length+50), height/2+(70));
    rectMode(CENTER);

    //change coordinates into more intuitive ones
    //x=0,y=0 is bottom center
    //positive is right and up
    translate(width*.65, height/2);
    scale(1, -1); 
    translate(0, -height/2);

    //move to location of first servo
    translate(0, height*.6);

    strokeWeight(10);

    //rotation of first servo
    rotate(radians(servo1Val));

    //color of c1
    stroke(0, 100, 100);

    //draw c1
    line(0, 0, 0, arm1Length);

    //move to location of second servo
    translate(0, arm1Length);

    //rotation of second servo
    rotate(radians(servo2Val)+PI);

    //color of c2
    stroke(100, 0, 100);

    //draw c2
    line(0, 0, 0, arm2Length);
    popMatrix();
    popStyle();
    if (keyboardCtrl.isPressed('w'))
      servo3Val=0;
    if (gamepadButton("Button 0", false)) {
      servo3Val=-gamepadVal("Z Axis", 0);
    }
    servo3Val=manual3Slider.run(servo3Val);
  }

  String[] msg={"battery voltage", "ping", "1 pos", "2 pos", "3 pos"};
  String[] data={str(batVolt), str(wifiPing), str(servo1PosTelem), str(servo2PosTelem), str(servo3Val)};
  dispTelem(msg, data, width/8, int(height*.6), width/4, int(height*.8), 30);

  sendWifiData(true);
  endOfDraw();
}

float[] cartToAngles(float x, float y, float c1, float c2) {
  float[] ret=new float[2];
  float s2=acos((-sq(x)-sq(y)+sq(c1)+sq(c2))/(2*c1*c2));
  if (x<0) {
    s2=-s2;
  }
  float s1=asin((c2*sin(s2))/sqrt(sq(x)+sq(y)))+atan(y/x)-PI/2;
  if (x<0) {
    s1=s1+PI;
  }

  ret[0]=s1;
  ret[1]=s2;
  return ret;
}

void WifiDataToRecv() {
  batVolt=recvFl();
  ////////////////////////////////////add data to read here
  servo1PosTelem=recvFl();
  servo2PosTelem=recvFl();
}
void WifiDataToSend() {
  sendBl(enabled);
  ///////////////////////////////////add data to send here
  sendBy(mode);
  if (mode==0||mode==1) {
    sendFl(servo1Val);
    sendFl(servo2Val);
    sendFl(servo3Val);
  }
}
