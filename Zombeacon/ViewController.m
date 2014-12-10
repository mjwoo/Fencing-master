//
//  ViewController.m
//  Zombeacon (tm)
//
// Copyright (c) 2014, Punch Through Design, LLC
// All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright
//notice, this list of conditions and the following disclaimer in the
//documentation and/or other materials provided with the distribution.
//3. Neither the name of the <organization> nor the
//names of its contributors may be used to endorse or promote products
//derived from this software without specific prior written permission.

//THIS SOFTWARE IS PROVIDED BY PUNCH THROUGH DESIGN, LLC ''AS IS'' AND ANY
//EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL PUNCH THROUGH DESIGN, LLC BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <mach/mach_time.h> //for mach_absolute_time

@interface ViewController () <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

// Location Manager Associated Types and primitives
@property (strong, nonatomic) CLLocationManager *locManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLBeaconRegion *zomBeaconRegion;
@property (strong, nonatomic) CLBeaconRegion *zomBeaconRegion2;
@property (assign, nonatomic) CLProximity lastProximity;
@property (assign, nonatomic) int proxFilter;

// Peripheral Manager Associated Types
@property (strong, nonatomic) CBPeripheralManager *beaconManager;
@property (strong, nonatomic) NSMutableDictionary *beaconAdvData;
@property (strong, nonatomic) NSMutableDictionary *zomBeaconAdvData;
@property (strong, nonatomic) NSMutableDictionary *zomBeaconAdvData2;

// AVFoundation Framework
@property (strong, nonatomic) NSArray *zombieSounds;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (assign, nonatomic) int zombiePlayFilter;

// Zombie images and gesture based state changes
@property (strong, nonatomic) UIImageView *greenImageBackground;
@property (strong, nonatomic) UIImageView *redImageBackground;
@property (strong, nonatomic) UIColor *zombieBgColor;
//@property (strong, nonatomic) UISwipeGestureRecognizer *rightRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *leftRecognizer;
@property (assign, nonatomic) bool isZombeacon;

@end


@implementation ViewController

// Constants

// Beacon configuration
static const int kMajorUninfected = 0;
static const int kMajorZombie = 1;
//NSString *const kBeaconUuid = @"95C8A575-0354-4ADE-8C6C-33E72CD84E9F";
NSString *const kBeaconUuid = @"A495FF10-C5B1-4B44-B512-1370F02D74DE";
NSString *const kBeaconIdentifier = @"Fencer 1";

// Second Blue Bean
NSString *const kBeaconUuid2= @"A4951234-C5B1-4B44-B512-1370F02D74DE";
NSString *const kBeaconIdentifier2 = @"Fencer 2";

// Filters and view opacity
static const int kProxFilterCount = 1;
static const int kZombieRssiAtOneMeter = -65;
static const int kZombiePlayDelay = 5;
static const float kLongestBeaconDistance = 4.0;
static const float kLightestZombieAlpha = 0.05f;



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // init primitives
    self.proxFilter = 0;
    self.isZombeacon = NO;
    self.zombiePlayFilter = 0;
    
    // Set up beacons
    
    // Used to calibrate proximity detection
    NSNumber *zomRssiAtOneMeter = [[NSNumber alloc] initWithInt:kZombieRssiAtOneMeter];
    
    // This UUID is the unique identifier for all Zombeacons and Beacons that monitor for Zombeacons.
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:kBeaconUuid];
    NSUUID *proximityUUID2 = [[NSUUID alloc] initWithUUIDString:kBeaconUuid2];
    
    // Be sure to register the view controller as the location manager delegate to obtain callbacks
    // for beacon monitoring
    self.locManager = [[CLLocationManager alloc] init];
    self.locManager.delegate = self;
    
#ifdef __IPHONE_8_0
    [self.locManager requestAlwaysAuthorization];
#endif
    
    // Initialize the CBPeripheralManager.  Advertising comes later.
    self.beaconManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                 queue:nil
                                                               options:nil];
    self.beaconManager.delegate = self;
    
    // These identify the beacon and Zombeacon regions used by CoreLocation
    // Notice that the proximity UUID and identifier are the same for each,
    // but that beacons and zombeacons have different major IDs.  We could
    // have used minor IDs in place of major IDs as well.
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                major:kMajorUninfected
                                                           identifier:kBeaconIdentifier];
    
    self.zomBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                   major:kMajorZombie
                                                              identifier:kBeaconIdentifier];

    
    self.zomBeaconRegion2 = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID2
                                                                    major:kMajorZombie
                                                               identifier:kBeaconIdentifier2];
    
    // Advertising NSDictionary objects created from the regions we defined
    // We add a local name for each, but it isn't a necessary step
    self.beaconAdvData = [self.beaconRegion peripheralDataWithMeasuredPower:zomRssiAtOneMeter];
    [self.beaconAdvData  setObject:@"Healthy Beacon"
                            forKey:CBAdvertisementDataLocalNameKey];
    
    self.zomBeaconAdvData = [self.zomBeaconRegion peripheralDataWithMeasuredPower:zomRssiAtOneMeter];
    [self.zomBeaconAdvData setObject:@"Zombeacon"
                              forKey:CBAdvertisementDataLocalNameKey];
    
    self.zomBeaconAdvData2 = [self.zomBeaconRegion2 peripheralDataWithMeasuredPower:zomRssiAtOneMeter];
    [self.zomBeaconAdvData2 setObject:@"Zombeacon"
                               forKey:CBAdvertisementDataLocalNameKey];
    
    // Set up the zombie background picture
    UIImage* greenPattern = [UIImage imageNamed:@"green_light.jpg"];
    UIImage* redPattern = [UIImage imageNamed:@"red_light.jpg"];
    self.zombieBgColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3];
    self.greenImageBackground = [[UIImageView alloc] initWithImage:greenPattern];
    self.redImageBackground = [[UIImageView alloc] initWithImage:redPattern];
    self.greenImageBackground.frame = CGRectMake(0, 0, 160, 720);
    self.redImageBackground.frame = CGRectMake(160, 0, 160, 720);
    // Initialize the opacity as essentially transparent
    self.greenImageBackground.alpha = kLightestZombieAlpha;
    self.redImageBackground.alpha = kLightestZombieAlpha;
    
    [self.view addSubview:self.greenImageBackground];
    [self.view sendSubviewToBack:self.greenImageBackground];
    [self.view addSubview:self.redImageBackground];
    [self.view sendSubviewToBack:self.redImageBackground];
    
    // set up gestures to turn on zombification.  Right for zombies, left for healthies
    /* Right swipe
     self.rightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
     action:@selector(rightSwipeHandle:)];
     
     self.rightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
     [self.rightRecognizer setNumberOfTouchesRequired:1];
     */
    
    self.leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(leftSwipeHandle:)];
    
    self.leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.leftRecognizer setNumberOfTouchesRequired:1];
    
    //[self.view addGestureRecognizer:self.rightRecognizer]; --Right Swipe Useless
    [self.view addGestureRecognizer:self.leftRecognizer];
    
    // Start looking for zombies
    [self startBeaconingUninfected];
}

// Sets device as a beacon or zombeacon
-(void)resetScore
{
    // Switch back to a healthy lifestyle
    self.greenImageBackground.alpha = kLightestZombieAlpha;
    self.greenImageBackground.backgroundColor = [UIColor clearColor];
    self.redImageBackground.alpha = kLightestZombieAlpha;
    self.redImageBackground.backgroundColor = [UIColor clearColor];
    
    self.isZombeacon = false;
    [self startBeaconingUninfected];
    
    // reset filter
    self.proxFilter = 0;
}

//Converts mach absolute time into nanoseconds
-(int)timeDifference:(uint64_t)machTime
{
    /* Get the timebase info */
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    uint64_t duration = mach_absolute_time() - machTime;
    
    /* Convert to nanoseconds */
    duration *= info.numer;
    duration /= info.denom;

    // Return the converted time difference
    return duration;
}

// Starts monitoring for infected beacons and advertises itself as a healthy beacon
-(void)startBeaconingUninfected
{
    // Advertise as a healthy beacon
    //[self.beaconManager stopAdvertising];
    
    //[self.locManager stopMonitoringForRegion:self.beaconRegion];
    //[self.locManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    [self.locManager startMonitoringForRegion:self.zomBeaconRegion];
    [self.locManager startRangingBeaconsInRegion:self.zomBeaconRegion];
    
    [self.locManager startMonitoringForRegion:self.zomBeaconRegion2];
    [self.locManager startRangingBeaconsInRegion:self.zomBeaconRegion2];
    
    [self.beaconManager startAdvertising:self.beaconAdvData];
}

// Starts monitoring for uninfected beacons and advertises itself as a zombeacon
-(void)startBeaconingInfected
{
    //[self.beaconManager stopAdvertising];
    
    //Want to keep looking for beacons
    //[self.locManager stopMonitoringForRegion:self.zomBeaconRegion];
    //[self.locManager stopRangingBeaconsInRegion:self.zomBeaconRegion];
    
    [self.locManager startMonitoringForRegion:self.beaconRegion];
    [self.locManager startRangingBeaconsInRegion:self.beaconRegion];
    
    [self.locManager startMonitoringForRegion:self.zomBeaconRegion2];
    [self.locManager startRangingBeaconsInRegion:self.zomBeaconRegion2];
    
    [self.beaconManager startAdvertising:self.zomBeaconAdvData];
}



// For debug
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"State Updated");
}

// For debug
-(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"Started advertising: %@", error);
}

// This is the method for discovering our beacons.  It looks for the beacons that we defined
// the regions for in ViewDidLoad.
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // We're only concerned with the nearest beacon, which is always the first object
    CLBeacon *nearestBeacon = [beacons firstObject];
    
    NSString *minorOneID = [NSString stringWithFormat:@"%@", nearestBeacon.minor];
    NSLog(@"START");
    NSLog(@"Minor ID CLose: %@", minorOneID);
    self.lastProximity = nearestBeacon.proximity;
    
    
    
    // Change the opacity of the zombie hand image as an example of using the distance
    // reading returned by CoreLocation
    /*
     if ( !self.isZombeacon)
     {
     //  assuming a reasonable max distance of kLongestBeaconDistance
     float newAlpha = ( kLongestBeaconDistance - nearestBeacon.accuracy ) / kLongestBeaconDistance;
     
     // If accuracy is farther than kLongestBeaconDistance, set opacity to the lightest defined
     if ( newAlpha < kLightestZombieAlpha )
     {
     newAlpha = kLightestZombieAlpha;
     }
     
     self.zombieImageBackground.alpha = newAlpha;
     NSLog(@"Nearest: %f", nearestBeacon.accuracy);
     }
     */
    
    // Debounce style filter - reset if proximity changes
    // This filter will ensure that a single reading of "Near" or "Immediate" doesn't
    // trigger a sound playback or beacon state switch immediately.  These are
    // George A. Romero style Zombeacons.
    if (nearestBeacon.proximity != self.lastProximity)
    {
        self.proxFilter = 0;
    }
    else
    {
        self.proxFilter++;
    }
    
    // Beacon must be in a certain proximity for a set amount of time before triggering events
    if ( self.proxFilter >= kProxFilterCount )
    {
        // If you are a zombeacon, and you notice a healthy beacon that is at least near to you,
        // groan as your hunger for brains is all consuming
        if ( self.isZombeacon
            && ( CLProximityNear == nearestBeacon.proximity
                || CLProximityImmediate == nearestBeacon.proximity ) )
        {
            self.zombiePlayFilter++;
            
            if ( self.zombiePlayFilter >= kZombiePlayDelay )
            {
                // Make sound
                [self playRandomZombieSound];
                self.zombiePlayFilter = 0;
            }
        }
        // The healthy beacon is bit if the zombeacon is at an immediate distance
        else if ( !self.isZombeacon && CLProximityFar == nearestBeacon.proximity )
        {
            // Become a zombeacon!
            //[self brainsAreTasty:YES];
            if ([nearestBeacon.minor isEqualToNumber:@250])
            {
                
                self.greenImageBackground.alpha = 1.0f;
                
                uint64_t start = mach_absolute_time();
                
                while (convertTime(start)) {
                    <#statements#>
                }
                
            }
            if ([nearestBeacon.minor isEqualToNumber:@23])
            {
                CFTimeInterval startTime = CACurrentMediaTime();
                self.redImageBackground.alpha = 1.0f;
                
                CFTimeInterval now = CACurrentMediaTime();
                CFTimeInterval elapsed = now - startTime;
                //NSLog(@"Start time: %f", elapsed);
                
                uint64_t start = mach_absolute_time();
                NSLog(@"Start: %qu", start);
                
            }
        }
        else if ( !self.isZombeacon && CLProximityImmediate == nearestBeacon.proximity )
        {
            // Become a zombeacon!
            //[self brainsAreTasty:YES];
            if ([nearestBeacon.minor isEqualToNumber:@250])
            {
                self.greenImageBackground.alpha = 1.0f;
                
                uint64_t start = mach_absolute_time();

            }
            if ([nearestBeacon.minor isEqualToNumber:@23])
            {
                CFTimeInterval startTime = CACurrentMediaTime();
                self.redImageBackground.alpha = 1.0f;
                
                CFTimeInterval now = CACurrentMediaTime();
                CFTimeInterval elapsed = now - startTime;
                
                uint64_t start = mach_absolute_time();
                NSLog(@"Start: %qu", start);
                
            }
        }
        else if ( !self.isZombeacon && CLProximityNear == nearestBeacon.proximity )
        {
            // Become a zombeaco
            //[self brainsAreTasty:YES];
            if ([nearestBeacon.minor isEqualToNumber:@250])
            {
                self.greenImageBackground.alpha = 1.0f;
                
                /* Get the timebase info */
                mach_timebase_info_data_t info;
                mach_timebase_info(&info);
                
                uint64_t start = mach_absolute_time();
                
                /* Do some code */
                
                uint64_t duration = mach_absolute_time() - start;
                
                /* Convert to nanoseconds */
                duration *= info.numer;
                duration /= info.denom;
                
                /* Log the time */
                NSLog(@"My amazing code took %lld nanoseconds!", duration);
                
                /*
                 if (elapsed < 5)
                 {
                 NSLog(@"Hello World");
                 self.redImageBackground.alpha = 1.0f;
                 }
                 */
            }
            if ([nearestBeacon.minor isEqualToNumber:@23])
            {
                self.redImageBackground.alpha = 1.0f;
                
                uint64_t start = mach_absolute_time();
                NSLog(@"Start: %qu", start);
            }
        }
        
    }
        //NSLog(@"Found Beacons: %lu", (unsigned long)[beacons count]);
        
    //NSLog(@"Found Beacons: %lu", (unsigned long)[beacons count]);
    uint64_t start = mach_absolute_time();
    NSLog(@"Start: %qu", start);
}

// Just for Debug
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"Monitoring for region: %@", region.identifier);
}

// Just for Debug
-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"Ranging Beacons Fail");
}

// Gesture that sets the state to zombeacon
/* Right Swipe Useless
 - (void)rightSwipeHandle:(UISwipeGestureRecognizer*)gestureRecognizer
 {
 [self playBite];
 [self brainsAreTasty:YES];
 }
 */

// Gesture that sets the state to a healthy beacon
- (void)leftSwipeHandle:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self resetScore];
}

// Randomized playback using AVFoundation Framework
-(void)playRandomZombieSound
{
    uint16_t randSoundIdx = random() % [self.zombieSounds count];
    NSError *error = nil;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.zombieSounds[randSoundIdx]
                                                              error:&error];
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
