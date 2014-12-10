void setup() {
    // initialize serial communication at 57600 bits per second:
    Serial.begin(9600);
    pinMode(0, OUTPUT);    // set D0 as output
    pinMode(A0, INPUT);
    digitalWrite(0, LOW);
}

// the loop routine runs over and over again forever:
void loop() {
  // read the input on analog pin 0:
  int sensorValue = analogRead(A0);
  // Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V):
  //float voltage = sensorValue * (5.0 / 1023.0);
  // print out the value you read:
  // Serial.println(sensorValue);
  //Serial.print(Bean.getBatteryLevel());

  if (sensorValue == 0.00)
  {
    /Serial.write("Touch Scored!\n");
    // Enable the advertising packets
    Bean.enableAdvertising( true, 1000 );
    //Bean.sleep(1000);
  }
  else
  {
    Bean.enableAdvertising(false); 
  }
  
  bool advertising = Bean.getAdvertisingState();
  if( advertising ){
    Bean.setLed(0,255,0);
    Bean.enableAdvertising(false);
  }
  else{
    Bean.setLed(0,0,0);
  }
  Bean.sleep(100);
}
