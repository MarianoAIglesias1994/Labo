#define BUFFERSIZE 127
uint8_t inBuffer[BUFFERSIZE];
int inLength; // length of data in the buffer
int numLoop = 0; // number of times we looped
int ledPin = 13;
void setup() { 
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT); 
} 
void loop() {
  // read string if available
  if (Serial.available()) {
    inLength =  0;
    while (Serial.available()) {
      inBuffer[ inLength] = Serial.read();
      inLength++;
      if (inLength >= BUFFERSIZE)
         break;
    }
  
    Serial.print("I received: ");
    Serial.write(inBuffer ,inLength);
    Serial.println();
  }
  // blink the led and send a number
  digitalWrite(ledPin, HIGH); // set the LED on
  delay(10); // wait a bit
  Serial.println(numLoop);
  digitalWrite(ledPin, LOW); // set the LED off
  delay(1000);
  numLoop++;
}
