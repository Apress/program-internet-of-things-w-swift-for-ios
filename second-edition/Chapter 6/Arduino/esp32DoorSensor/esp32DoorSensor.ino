#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

#define RED_LED_PIN 14
#define BLUE_LED_PIN 15
#define SWITCH_PIN 33
#define BATTERY_PIN 35

#define LOCK_SERVICE_UUID        "83b41811-6e9c-4b25-89cf-871cc74cc68e"
#define BATT_SERVICE_UUID        "7d69180F-6e19-48c6-a503-05585abe761e"
#define LOCK_CHARACTERISTIC_UUID "4b612A3F-2e29-4fdf-a74a-7b8bf70ecd9a"
#define BATT_CHARACTERISTIC_UUID "8e622A1B-0275-4f80-bb64-58f2b2771cba"

boolean isHigh = true;
int switchState = 0;
float batteryLevel = 0;

//TODO MAKE THIS UNIQUE

BLECharacteristic *lockCharacteristic;
BLECharacteristic *battCharacteristic;
bool deviceConnected = false;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      digitalWrite(BLUE_LED_PIN, deviceConnected);
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      digitalWrite(BLUE_LED_PIN, deviceConnected);
    }
};



void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); 
  Serial.println(" Program start");
  
  pinMode(RED_LED_PIN, OUTPUT);
  pinMode(BLUE_LED_PIN, OUTPUT);
  pinMode(SWITCH_PIN, INPUT);
  pinMode(BATTERY_PIN, INPUT);
  startBLE();
}

void loop() {
  // put your main code here, to run repeatedly:
  checkSensor();  
  checkBattery();
  delay(1000);
}

void blinkLed() {
  digitalWrite(BLUE_LED_PIN, isHigh);
  isHigh = !isHigh;
}

void checkSensor() {
  int currentState = digitalRead(SWITCH_PIN);
  if (currentState != switchState) {
    updateLockBLE(currentState);
  }
  switchState = currentState;
  digitalWrite(RED_LED_PIN, switchState);
  Serial.print("Sensor state: "); 
  Serial.println(switchState);
}

void checkBattery() {
   float currentLevel = analogRead(BATTERY_PIN);
   currentLevel = ((currentLevel / 4095) * 2 * 3.3 * 1.1) * 100 / 4.3;
   if (currentLevel > batteryLevel + 5.0 ) {
      updateBatteryBLE(currentLevel); 
   }
   batteryLevel = currentLevel;
   Serial.print("Battery Level: "); 
   Serial.print(batteryLevel);
   Serial.println("%");
}


void startBLE() {
   // Create the BLE Device
  BLEDevice::init("IOTDoor");

  // Create the BLE Server
  BLEServer *bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *lockService = bleServer->createService(LOCK_SERVICE_UUID);

  // Create a BLE Characteristic
  lockCharacteristic = lockService->createCharacteristic(
                      LOCK_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  
  lockCharacteristic->addDescriptor(new BLE2902());

  BLEService *battService = bleServer->createService(BATT_SERVICE_UUID);
  
  battCharacteristic = lockService->createCharacteristic(
                      BATT_CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );
  battCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  lockService->start();
  battService->start();

  // Start advertising
  bleServer->getAdvertising()->start();
}

void updateLockBLE(bool currentState) {

    uint8_t value = 0;
    if (deviceConnected) {
      //lockCharacteristic->setValue(currentState ? "Locked" : "Unlocked");
      value = currentState ? 1 : 0;
      lockCharacteristic->setValue(&value, 1);
      lockCharacteristic->notify();
    }
}

void updateBatteryBLE(float currentLevel) {
    if (deviceConnected) {
      char string[8];
      dtostrf(currentLevel, 3, 1, string);
      battCharacteristic->setValue(string);
      battCharacteristic->notify();
    }
}

