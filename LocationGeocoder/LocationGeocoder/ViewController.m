//
//  ViewController.m
//  LocationGeocoder
//
//  Created by Hoang Pham on 10/21/14.
//  Copyright (c) 2014 Hoang Pham. All rights reserved.
//

#import "ViewController.h"
#import "FCCurrentLocationGeocoder.h"

@interface ViewController ()

@end

@implementation ViewController


- (FCCurrentLocationGeocoder *)setupLocationGeoCoderWithKey: (NSString *)geocoderKey
{
	FCCurrentLocationGeocoder *geocoder = [FCCurrentLocationGeocoder sharedGeocoderForKey: geocoderKey];
	geocoder.canPromptForAuthorization = YES;
	geocoder.canUseIPAddressAsFallback = YES;
	geocoder.timeFilter = 30;
	geocoder.timeoutErrorDelay = 10;
	return geocoder;
}

- (void) forwardGeocode
{
	FCCurrentLocationGeocoder *geocoder = [self setupLocationGeoCoderWithKey:@"forwardGeocoding"];
	
	if ([geocoder canGeocode])
	{
		[geocoder geocode:^(BOOL success) {
			if (success){
				NSLog(@"geocode success: %@", geocoder.location.description);
				// my test results:
				// geocode success: <+45.49916327,+9.12219525> +/- 65.00m (speed -1.00 mps / course -1.00) @ 10/21/14, 10:24:14 AM Central European Summer Time
			}
			else
			{
				NSLog(@"geocode error: %@", geocoder.error);
			}
		}];
	}
}

- (void)reverseGeocode
{
	FCCurrentLocationGeocoder *geocoder = [self setupLocationGeoCoderWithKey:@"reverseGeocoding"];
	
	if ([geocoder canGeocode]) {
		[geocoder reverseGeocode:^(BOOL success) {
			if (success)
			{
				NSLog(@"reverse success: %@ - %@", geocoder.locationAddress, geocoder.locationCity);
				// my test results:
				// reverse success: Via Privata Grosio 10/10–10/6, 20151 Milan, Italy - Milan
			}
		}];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	[self forwardGeocode];
	
	[self reverseGeocode];
}

@end
