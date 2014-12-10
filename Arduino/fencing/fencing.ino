void setup() {
    // initialize serial communication at 9600 bits per second:
    Serial.begin(9600);
    pinMode(0, OUTPUT);    // set D0 as output
    pinMode(A0, INPUT);
    digitalWrite(0, LOW);
}

// the loop routine runs over and over again forever:
void loop() {
  // read the input on analog pin 0:
  int sensorValue = analogRead(A0);

  if (sensorValue == 0.00)
  {
    //Serial.write("Touch Scored!\n");
    // Enable the advertising packets
    Bean.enableAdvertising( true, 1000 );
    Bean.sleep(1000);
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
}
