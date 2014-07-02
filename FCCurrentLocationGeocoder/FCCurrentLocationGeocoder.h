//
//  FCCurrentLocationGeocoder.h
//
//  Created by Fabio Caccamo on 11/08/12.
//  Copyright (c) 2012 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

void (^completion)(BOOL success);

@interface FCCurrentLocationGeocoder : NSObject <CLLocationManagerDelegate>
{
    NSTimer *_timeoutErrorTimer;
    CLLocationManager *_locationManager;
    
    CLLocation *_bestLocation;
    NSTimer *_bestLocationAttemptTimeoutTimer;
    NSTimeInterval _bestLocationAttemptTimeout;
    int _bestLocationAttemptsCounter;
    int _bestLocationAttemptsLimit;
    
    BOOL _reverse;
    CLGeocoder *_reverseGeocoder;
}

@property (nonatomic, readwrite) BOOL canPromptForAuthorization;

@property (nonatomic, readwrite) NSTimeInterval timeFilter;
@property (nonatomic, readwrite) NSTimeInterval timeoutErrorDelay;

@property (nonatomic, readonly, getter = isGeocoding) BOOL geocoding;

@property (nonatomic, readonly, copy) CLLocation *location;
@property (nonatomic, readonly, copy) NSArray *locationPlacemarks;
@property (nonatomic, readonly, copy) CLPlacemark *locationPlacemark;
@property (nonatomic, readonly, copy) NSString *locationCountry;
@property (nonatomic, readonly, copy) NSString *locationCountryCode;
@property (nonatomic, readonly, copy) NSString *locationCity;
@property (nonatomic, readonly, copy) NSString *locationZipCode;
@property (nonatomic, readonly, copy) NSString *locationAddress;

@property (nonatomic, readonly, strong) NSError *error;

-(void)cancelGeocode;
-(BOOL)canGeocode;
+(BOOL)canGeocode;
+(BOOL)canGeocodeWithoutPromptForAuthorization;
-(void)geocode:(void(^)(BOOL success))completionHandler;
-(void)reverseGeocode:(void(^)(BOOL success))completionHandler;
+(FCCurrentLocationGeocoder *)sharedGeocoder;

@end