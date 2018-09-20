#define RED_LED_PIN 14
#define BLUE_LED_PIN 15
#define SWITCH_PIN 33
#define BATTERY_PIN 35

boolean isHigh = true;
int switchState = 0;
float batteryLevel = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); 
  Serial.println(" Program start");
  
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BLUE_LED_PIN, OUTPUT);
  pinMode(SWITCH_PIN, INPUT);
  pinMode(BATTERY_PIN, INPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  checkSwitch();  
  checkBattery();
  delay(1000);
}

void checkSwitch() {
  int currentState = digitalRead(SWITCH_PIN);
  if (currentState != switchState) {
    updateLockBLE(currentState);
  }
  switchState = currentState;
  digitalWrite(RED_LED_PIN, switchState);
  Serial.print("Switch state: "); 
  Serial.println(switchState);
}

void checkBattery() {
   float currentLevel = analogRead(BATTERY_PIN);
   currentLevel = ((currentLevel / 4095) * 2 * 3.3 * 1.1) * 100 / 4.3;
   batteryLevel = currentLevel;
   Serial.print("Battery Level: "); 
   Serial.print(batteryLevel);
   Serial.println("%");
}


