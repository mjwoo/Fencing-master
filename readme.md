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
-------------------
Using the Arduino application, upload the fencing.ino sketch to the Light Blue Bean. Make sure the directory in the Arduino preferences is set to the source folder. To set the Light Blue Bean as an iBeacon, follow the instructions here: https://punchthrough.com/bean/ibeacon-setup/

We set our Major and Minor ID's as [0,250] and [1,23], but make sure to change those constants in ViewController.m if you set them to something else.

