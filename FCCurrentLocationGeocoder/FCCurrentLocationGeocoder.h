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
    CLLocationManager *_manager;
    
    CLLocation *_bestLocation;
    int _bestLocationAttempts;
    
    BOOL _reverse;
    CLGeocoder *_geocoder;
    NSTimer *_timer;
}

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
@property (nonatomic) double timeout;
@property (nonatomic, getter = canPromptForAuthorization) BOOL prompt;

-(void)cancelGeocode;
+(BOOL)canGeocodeIfCanPromptForAuthorization:(BOOL)canPromptForAuthorization;
+(BOOL)canGeocodeWithPromptForAuthorization;
+(BOOL)canGeocodeWithoutPromptForAuthorization;
-(BOOL)canGeocode;
-(void)geocode:(void(^)(BOOL success))completionHandler;
-(void)reverseGeocode:(void(^)(BOOL success))completionHandler;

@end