BLE FENCING

Using Light Blue Bean and Bluetooth Low Energy to replace the body and reel wires in epee fencing

Jeffrey Zhao, Michael Woo, Ace Eldeib

Setting up the Arduino
-------------------
Using the Arduino application, upload the fencing.ino sketch to the Light Blue Bean. Make sure the directory in the Arduino preferences is set to the correct folder. To set the Light Blue Bean as an iBeacon, follow the instructions here: https://punchthrough.com/bean/ibeacon-setup/

We set our Major and Minor ID's as [0,250] and [1,23], but make sure to change those constants in ViewController.m if you set them to something else.

ViewController.m
-------------------



```objective-c
            //  assuming a reasonable max distance of kLongestBeaconDistance
            float newAlpha = ( kLongestBeaconDistance - nearestBeacon.accuracy ) / kLongestBeaconDistance;
```

