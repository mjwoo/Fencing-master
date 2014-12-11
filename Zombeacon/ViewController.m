//
//  ViewController.m

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <mach/mach_time.h> //for mach_absolute_time

@interface ViewController () <CBPeripheralManagerDelegate, CLLocationManagerDelegate>

// Location Manager Associated Types and primitives
@property (strong, nonatomic) CLLocationManager *locManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLBeaconRegion *FencebeaconRegion;
@property (strong, nonatomic) CLBeaconRegion *FencebeaconRegion2;
@property (assign, nonatomic) CLProximity lastProximity;
@property (assign, nonatomic) int proxFilter;

// Peripheral Manager Associated Types
@property (strong, nonatomic) CBPeripheralManager *beaconManager;
@property (strong, nonatomic) NSMutableDictionary *beaconAdvData;
@property (strong, nonatomic) NSMutableDictionary *FencebeaconAdvData;
@property (strong, nonatomic) NSMutableDictionary *FencebeaconAdvData2;

// fencer images and gesture based state changes
@property (strong, nonatomic) UIImageView *greenImageBackground;
@property (strong, nonatomic) UIImageView *redImageBackground;
@property (strong, nonatomic) UIColor *fencerBgColor;
//@property (strong, nonatomic) UISwipeGestureRecognizer *rightRecognizer;
@property (strong, nonatomic) UISwipeGestureRecognizer *leftRecognizer;
@property (assign, nonatomic) bool isFencebeacon;

@end


@implementation ViewController

// Constants

// Beacon configuration
static const int kMajorReset = 0;
static const int kMajorfencer = 1;
static const int kMinorGreen = 250;
static const int kMinorRed = 23;
//NSString *const kBeaconUuid = @"95C8A575-0354-4ADE-8C6C-33E72CD84E9F";
NSString *const kBeaconUuid = @"A495FF10-C5B1-4B44-B512-1370F02D74DE";
NSString *const kBeaconIdentifier = @"Fencer 1";

// Second Blue Bean
NSString *const kBeaconUuid2= @"A4951234-C5B1-4B44-B512-1370F02D74DE";
NSString *const kBeaconIdentifier2 = @"Fencer 2";

// Filters and view opacity
static const int kProxFilterCount = 1;
static const int kfencerRssiAtOneMeter = -65;
static const int kfencerPlayDelay = 5;
static const float kLongestBeaconDistance = 4.0;
static const float kLightestfencerAlpha = 0.05f;

static uint64_t globalGreen = 0;
static uint64_t globalRed = 0;


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // init primitives
    self.proxFilter = 0;
    self.isFencebeacon = NO;
    
    // Set up beacons
    
    // Used to calibrate proximity detection
    NSNumber *fencerRssiAtOneMeter = [[NSNumber alloc] initWithInt:kfencerRssiAtOneMeter];
    
    // This UUID is the unique identifier for all Fencebeacons and Beacons that monitor for Fencebeacons.
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
    
    // These identify the beacon and Fencebeacon regions used by CoreLocation
    // Notice that the proximity UUID and identifier are the same for each,
    // but that beacons and Fencebeacons have different major IDs.  We could
    // have used minor IDs in place of major IDs as well.
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                major:kMajorReset
                                                           identifier:kBeaconIdentifier];
    
    self.FencebeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID
                                                                   major:kMajorfencer
                                                              identifier:kBeaconIdentifier];

    
    self.FencebeaconRegion2 = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID2
                                                                    major:kMajorfencer
                                                               identifier:kBeaconIdentifier2];
    
    // Advertising NSDictionary objects created from the regions we defined
    // We add a local name for each, but it isn't a necessary step
    self.beaconAdvData = [self.beaconRegion peripheralDataWithMeasuredPower:fencerRssiAtOneMeter];
    [self.beaconAdvData  setObject:@"Healthy Beacon"
                            forKey:CBAdvertisementDataLocalNameKey];
    
    self.FencebeaconAdvData = [self.FencebeaconRegion peripheralDataWithMeasuredPower:fencerRssiAtOneMeter];
    [self.FencebeaconAdvData setObject:@"Fencebeacon"
                              forKey:CBAdvertisementDataLocalNameKey];
    
    self.FencebeaconAdvData2 = [self.FencebeaconRegion2 peripheralDataWithMeasuredPower:fencerRssiAtOneMeter];
    [self.FencebeaconAdvData2 setObject:@"Fencebeacon"
                               forKey:CBAdvertisementDataLocalNameKey];
    
    // Set up the background picture
    UIImage* greenPattern = [UIImage imageNamed:@"green_light.jpg"];
    UIImage* redPattern = [UIImage imageNamed:@"red_light.jpg"];
    self.fencerBgColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3];
    self.greenImageBackground = [[UIImageView alloc] initWithImage:greenPattern];
    self.redImageBackground = [[UIImageView alloc] initWithImage:redPattern];
    self.greenImageBackground.frame = CGRectMake(0, 0, 160, 720);
    self.redImageBackground.frame = CGRectMake(160, 0, 160, 720);
    // Initialize the opacity as essentially transparent
    self.greenImageBackground.alpha = kLightestfencerAlpha;
    self.redImageBackground.alpha = kLightestfencerAlpha;
    
    [self.view addSubview:self.greenImageBackground];
    [self.view sendSubviewToBack:self.greenImageBackground];
    [self.view addSubview:self.redImageBackground];
    [self.view sendSubviewToBack:self.redImageBackground];
    
    self.leftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(leftSwipeHandle:)];
    
    self.leftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.leftRecognizer setNumberOfTouchesRequired:1];
    
    [self.view addGestureRecognizer:self.leftRecognizer];
    
    // Start looking for fencers
    [self startBeaconingReset];
}

// Sets device as a beacon or Fencebeacon
-(void)resetScore
{
    // Switch back to a healthy lifestyle
    self.greenImageBackground.alpha = kLightestfencerAlpha;
    self.greenImageBackground.backgroundColor = [UIColor clearColor];
    self.redImageBackground.alpha = kLightestfencerAlpha;
    self.redImageBackground.backgroundColor = [UIColor clearColor];
    
    self.isFencebeacon = false;
    [self startBeaconingReset];
    
    // reset filter
    self.proxFilter = 0;
}

-(void)checkWithinTimeGreen:(NSNumber *)kMinor nearBeacon:(CLBeacon *)nearBeacon
{
    while ([self timeDifference:globalRed] < 1000000000)
    {
        self.greenImageBackground.alpha = 1.0f;
        NSLog(@"TIME DIFFERENCE WORKS");
    }
    [self lockout];
}

-(void)checkWithinTimeRed:(NSNumber *)kMinor nearBeacon:(CLBeacon *)nearBeacon
{
    while ([self timeDifference:globalGreen] < 1000000000)
    {
        self.redImageBackground.alpha = 1.0f;
        NSLog(@"TIME DIFFERENCE WORKS");
    }
    [self lockout];
}

//Converts mach absolute time into nanoseconds
-(unsigned long long)timeDifference:(uint64_t)machTime
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

-(void)lockout
{
    self.greenImageBackground.backgroundColor = self.fencerBgColor;
    self.redImageBackground.backgroundColor = self.fencerBgColor;
    self.isFencebeacon = true;
}

// Starts monitoring for Scored beacons and advertises itself as a healthy beacon
-(void)startBeaconingReset
{   
    [self.locManager startMonitoringForRegion:self.FencebeaconRegion];
    [self.locManager startRangingBeaconsInRegion:self.FencebeaconRegion];
    
    [self.locManager startMonitoringForRegion:self.FencebeaconRegion2];
    [self.locManager startRangingBeaconsInRegion:self.FencebeaconRegion2];
    
    [self.beaconManager startAdvertising:self.beaconAdvData];
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
    
    
    // Debounce style filter - reset if proximity changes
    // This filter will ensure that a single reading of "Near" or "Immediate" doesn't
    // trigger a sound playback or beacon state switch immediately.  These are
    // George A. Romero style Fencebeacons.
    if (nearestBeacon.proximity != self.lastProximity)
    {
        self.proxFilter = 0;
    }
    else
    {
        self.proxFilter++;
    }
    
        // The healthy beacon is bit if the Fencebeacon is at an immediate distance
        if ( !self.isFencebeacon && CLProximityFar == nearestBeacon.proximity )
        {
            // Become a Fencebeacon!
            //[self brainsAreTasty:YES];

            // Received green packet and both score sides are blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == .05f && self.greenImageBackground.alpha == .05f)
            {
                self.greenImageBackground.alpha = 1.0f;
                globalGreen = mach_absolute_time();
            }
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == .05f && self.greenImageBackground.alpha == 1.0f)
            {
                self.greenImageBackground.alpha = 1.0f;
            }

            // Received red packet and both score sides are blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == .05f && self.redImageBackground.alpha == 0.05f)
            {
                self.redImageBackground.alpha = 1.0f;
                globalRed = mach_absolute_time();
            }
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == .05f && self.redImageBackground.alpha == 1.0f)
            {
                self.redImageBackground.alpha = 1.0f;
            }
            // Receives green packet and red is lit but green is blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == 1.0f && self.greenImageBackground.alpha == 0.05f)
            {
                [self checkWithinTimeGreen:[NSNumber numberWithInt:kMinorGreen] nearBeacon:nearestBeacon];
                
            }

            //Receives red packet and green is lit but red is blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == 1.0f && self.redImageBackground.alpha == 0.05f)
            {
                [self checkWithinTimeRed:[NSNumber numberWithInt:kMinorRed] nearBeacon:nearestBeacon];
            }
            //Receives red packet and both are lit

        }
        else if ( !self.isFencebeacon && CLProximityImmediate == nearestBeacon.proximity )
        {
            // Become a Fencebeacon!
            //[self brainsAreTasty:YES];
            // Received green packet and both score sides are blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == .05f && self.greenImageBackground.alpha == .05f)
            {
                self.greenImageBackground.alpha = 1.0f;
                globalGreen = mach_absolute_time();
            }
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == .05f && self.greenImageBackground.alpha == 1.0f)
            {
                self.greenImageBackground.alpha = 1.0f;
            }
            // Received red packet and both score sides are blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == .05f && self.redImageBackground.alpha == 0.05f)
            {
                self.redImageBackground.alpha = 1.0f;
                globalRed = mach_absolute_time();
            }
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == .05f && self.redImageBackground.alpha == 1.0f)
            {
                self.redImageBackground.alpha = 1.0f;
            }
            // Receives green packet and red is lit but green is blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == 1.0f && self.greenImageBackground.alpha == 0.05f)
            {
                [self checkWithinTimeRed:[NSNumber numberWithInt:kMinorRed] nearBeacon:nearestBeacon];
            }
            //Receives red packet and green is lit but red is blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == 1.0f && self.redImageBackground.alpha == 0.05f)
            {
                [self checkWithinTimeRed:[NSNumber numberWithInt:kMinorRed] nearBeacon:nearestBeacon];
            }

        }
        else if ( !self.isFencebeacon && CLProximityNear == nearestBeacon.proximity )
        {
            // Become a fencerbeaco
            //[self brainsAreTasty:YES];
            // Received green packet and both score sides are blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == .05f && self.greenImageBackground.alpha == .05f)
            {
                self.greenImageBackground.alpha = 1.0f;
                globalGreen = mach_absolute_time();
            }
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == .05f && self.greenImageBackground.alpha == 1.0f)
            {
                self.greenImageBackground.alpha = 1.0f;
            }
            // Received red packet and both score sides are blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == .05f && self.redImageBackground.alpha == 0.05f)
            {
                self.redImageBackground.alpha = 1.0f;
                globalRed = mach_absolute_time();
            }
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == .05f && self.redImageBackground.alpha == 1.0f)
            {
                self.redImageBackground.alpha = 1.0f;
            }
            // Receives green packet and red is lit but green is blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorGreen)] && self.redImageBackground.alpha == 1.0f && self.greenImageBackground.alpha == 0.05f)
            {
                [self checkWithinTimeGreen:[NSNumber numberWithInt:kMinorGreen] nearBeacon:nearestBeacon];
                
            }
            //Receives red packet and green is lit but red is blank
            if ([nearestBeacon.minor isEqualToNumber:@(kMinorRed)] && self.greenImageBackground.alpha == 1.0f && self.redImageBackground.alpha == 0.05f)
            {
                [self checkWithinTimeRed:[NSNumber numberWithInt:kMinorRed] nearBeacon:nearestBeacon];
            }

        }
        
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


// Gesture that sets the state to a healthy beacon
- (void)leftSwipeHandle:(UISwipeGestureRecognizer*)gestureRecognizer
{
    [self resetScore];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end