BLE FENCING

Using Light Blue Bean and Bluetooth Low Energy to replace the body and reel wires in epee fencing

Jeffrey Zhao, Michael Woo, Ace Eldeib

Preparation
___________________

1) Download and install the Arduino app

2) Download and install the LightBlue Bean Loader app.

3) Associate the Loader app with the Arduino app.

4) Power on iBeacons (by inserting batteries) and ensure they can be detected and are set as iBeacons. 

5) Make sure iBeacon ID's are set properly as below. 

Setting up the Arduino
___________________
Using the Arduino application, upload the fencing.ino sketch to the Light Blue Bean. Make sure the directory in the Arduino preferences is set to the source folder. To set the Light Blue Bean as an iBeacon, follow the instructions here: https://punchthrough.com/bean/ibeacon-setup/

We set our Major and Minor ID's as [0,250] and [1,23], but make sure to change those constants in ViewController.m if you set them to something else.

Running the Application
___________________
In order to run the application, simply download and install the app onto an iOS device with BLE capabilities.

Then hook up the LightBlue Bean with attached wiring and prongs to an Epee.  if the bean is in range of the iOS device, then when the Epee tip is compressed, the respective light of the bean and epee fencer will be lit up.  

After an action resulting in a touch has occurred, the referee can reset the lights simply by swiping left.

LAYOUT
-----------
In ViewController.m the specific functions and their purposes are commented, but the general layout is that the general step is that we range and monitor for other beacons with our central beacon (iOS device). When found, we listen for it to broadcast an advertising packet. We have the UUID, Major, and Minor ID's so it is easy to identify the specific beacons. Then, depending on which lights have already been triggered (e.g. if any advertising packets have already been sent, and if so, which ones), we call lockout functionality.


ACKNOWLEDGEMENTS
___________________

We would like to acknowledge the developers of LightBlue Bean and their Zombeacon demo application displaying how to use the Lightblue Beans as iBeacons.  While Zombeacon did not provide us with any actual fencing applications, it did provide us with a skeleton framework to start adding code to our iOS device.  