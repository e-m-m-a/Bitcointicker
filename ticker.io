#include <ESP8266WiFi.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include "SSD1306.h"

SSD1306  display(0x3c, D1, D2);


// Previous Bitcoin value & threshold
float previousValue = 0.0000;
float threshold = 0.0001;

// WiFi settings
const char* ssid     = "Apple Network";
const char* password = "jamietom";

// API server
const char* host = "api.coindesk.com";

void setup() {


//show life

  pinMode(LED_BUILTIN, OUTPUT);     // Initialize the LED_BUILTIN pin as an output


  // Serial
  Serial.begin(115200);
  delay(10);

   // Initialize display
  display.init();
  display.flipScreenVertically();
  display.clear();
  display.display();


  // We start by connecting to a WiFi network
  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");  
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}


void loop() {

  // Connect to API
  Serial.print("connecting to ");
  Serial.println(host);
  
  // Use WiFiClient class to create TCP connections
  WiFiClient client;
  const int httpPort = 80;
  if (!client.connect(host, httpPort)) {
    Serial.println("connection failed");
    return;
  }
  
//blink

  digitalWrite(LED_BUILTIN, LOW);   // Turn the LED on by making the voltage LOW
  delay(100);                      // Wait for a second
  digitalWrite(LED_BUILTIN, HIGH);  // Turn the LED off by making the voltage HIGH
  delay(2000);                      // Wait for two seconds

  
  // We now create a URI for the request
  String url = "/v1/bpi/currentprice.json";
  
  Serial.print("Requesting URL: ");
  Serial.println(url);
  
  // This will send the request to the server
  client.print(String("GET ") + url + " HTTP/1.1\r\n" +
               "Host: " + host + "\r\n" + 
               "Connection: close\r\n\r\n");
  delay(100);
  
  // Read all the lines of the reply from server and print them to Serial
  String answer;
  while(client.available()){
    String line = client.readStringUntil('\r');
    answer += line;
  }

  client.stop();
  Serial.println();
  Serial.println("closing connection");

  // Process answer
  Serial.println();
  Serial.println("Answer: ");
  Serial.println(answer);

  // Convert to JSON
  String jsonAnswer;
  int jsonIndex;



// Get Rate as Float
int rateIndex = answer.indexOf("rate_float");  // Get the index of the start of the rate info
String priceString = answer.substring(rateIndex + 12, rateIndex + 20);  // Select only the rate data
priceString.trim();  // Remove any leading/trailing white spaces
float price = priceString.toFloat();  // Convert the string to a number

// Print it to the display
Serial.println(); 
Serial.println("Bitcoin price: "); 
Serial.println(price);

  // Display on OLED
  display.clear();
  display.setFont(ArialMT_Plain_16);
  display.drawString(0, 0, "Bitcoin Price:");
  display.setFont(ArialMT_Plain_24);
  display.drawString(0, 22, "$");
  display.drawString(16, 22, priceString);
  display.display();

  // Init previous value 
  if (previousValue == 0.0) {
    previousValue = price;
  }

  // Alert down ?
  if (price < (previousValue - threshold)) {

    // show down
  display.setFont(ArialMT_Plain_10);
  display.drawString(0, 52, "Down. Hodl.");
  display.display();
    
  }

  // Alert up ?
  if (price > (previousValue + threshold)) {

    // Write to screen
  display.setFont(ArialMT_Plain_10);
  display.drawString(0, 52, "Up. Hodl.");
  display.display();
  }

  // Store value
  previousValue = price;

  // Wait 5 Secondse
  delay(5000);
}
