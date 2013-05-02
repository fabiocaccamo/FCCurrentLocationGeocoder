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
    CLLocationManager * _manager;
    CLGeocoder * _geocoder;
    NSTimer * _timer;
}

@property (nonatomic, readonly, getter = isGeocoding) BOOL geocoding;
@property (nonatomic, readonly, copy) CLLocation * location;
@property (nonatomic, readonly, copy) NSArray * locationPlacemarks;
@property (nonatomic, readonly, copy) CLPlacemark * locationPlacemark;
@property (nonatomic, readonly, strong) NSError * error;
@property (nonatomic) double timeout;


+(id)geocoder;
+(id)geocoderWithTimeout:(double)timeout;


-(id)initWithTimeout:(double)timeout;


-(void)cancelGeocode;
-(void)geocode:(void(^)(BOOL success))completionHandler;
-(void)reverseGeocode:(void(^)(BOOL success))completionHandler;

@end
