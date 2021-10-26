//   https://github.com/rcmgames/RCMv2
#include <ESP32_easy_wifi_data.h> //https://github.com/joshua-8/ESP32_easy_wifi_data
#include <JMotor.h> //https://github.com/joshua-8/JMotor
#include "rcm.h" //defines pins

const int dacUnitsPerVolt = 380;
JVoltageCompMeasure<10> voltageComp = JVoltageCompMeasure<10>(batMonitorPin, dacUnitsPerVolt);

JMotorDriverEsp32Servo servo1Driver = JMotorDriverEsp32Servo(port2);
JServoController servo1 = JServoController(servo1Driver, true, INFINITY, INFINITY, 0, -90, 90, 0, -90 - 45, 90 + 45, 544, 2400);

JMotorDriverEsp32Servo servo2Driver = JMotorDriverEsp32Servo(port4);
JServoController servo2 = JServoController(servo2Driver, false, INFINITY, INFINITY, 0, 0, 180, 0, 0, 180, 544, 2400);

JMotorDriverEsp32Servo servo3 = JMotorDriverEsp32Servo(port3);

byte mode = 0;
float servo1Set = 0;
float servo2Set = 90;
float servo3Set = 0;

void configWifi() { //see https://github.com/joshua-8/ESP32_easy_wifi_data/blob/master/examples/fullExample/fullExample.ino
  EWD::routerName = "chicken"; //name of the wifi network you want to connect to
  EWD::routerPass = "bawkbawk"; //password for your wifi network (enter "-open-network-" if the network has no password) (default: -open-network-)
  EWD::wifiPort = 25220; //what port the esp32 communicates on if connected to a wifi network (default: 25210)
}

void Enabled() {
  //code to run while enabled

}

void Enable() {
  //turn on outputs
  servo1.enable();
  servo2.enable();
  servo3.enable();
}
//
void Disable() {
  //shut off all outputs
  servo1.disable();
  servo2.disable();
  servo3.disable();
}

void PowerOn() {
  //runs once on robot startup, set pinmodes
  servo2.setAngleImmediate(90);
}

void Always() {
  //always runs if void loop is running, don't control outputs here
  if (mode == 0 || mode == 1) {
    servo1.setAngleSmoothed(servo1Set);
    servo2.setAngleSmoothed(servo2Set);
    servo3.set(servo3Set + .035); //trim continuous servo
  }
}

void WifiDataToParse() {
  enabled = EWD::recvBl();
  //add data to read here: (EWD::recvBl, EWD::recvBy, EWD::recvIn, EWD::recvFl)(boolean, byte, int, float)
  mode = EWD::recvBy();
  if (mode == 0 || mode == 1) {
    servo1Set = EWD::recvFl();
    servo2Set = EWD::recvFl();
    servo3Set = EWD::recvFl();
  }
}
void WifiDataToSend() {
  EWD::sendFl(voltageComp.getSupplyVoltage());
  //add data to send here:
  servo1.isPosAtTarget();
  EWD::sendFl(servo1.getPos());
  EWD::sendFl(servo2.getPos());
}

void setup() {
  Serial.begin(115200);
  PowerOn();
  pinMode(ONBOARD_LED, OUTPUT);
  Disable();
  configWifi();
  EWD::setupWifi(WifiDataToParse, WifiDataToSend);
}

void loop() {
  EWD::runWifiCommunication();
  if (EWD::timedOut()) {
    enabled = false;
  }
  Always();
  if (enabled && !wasEnabled) {
    Enable();
  }
  if (!enabled && wasEnabled) {
    Disable();
  }
  if (enabled) {
    Enabled();
    digitalWrite(ONBOARD_LED, millis() % 500 < 250);
  } else {
    digitalWrite(ONBOARD_LED, HIGH);
  }
  wasEnabled = enabled;
}
