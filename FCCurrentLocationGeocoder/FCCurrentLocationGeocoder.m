//
//  Geolocation.m
//
//  Created by Fabio Caccamo on 11/08/12.
//  Copyright (c) 2012 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import "FCCurrentLocationGeocoder.h"

@implementation FCCurrentLocationGeocoder


+(id)geocoder
{
    return [[FCCurrentLocationGeocoder alloc] init];
}


+(id)geocoderWithTimeout:(double)timeout
{
    return [[FCCurrentLocationGeocoder alloc] initWithTimeout:timeout];
}


-(id)init 
{
    self = [super init];
    
    if(self)
    {
        _geocoding = FALSE;
        
        _location = nil;
        
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        //manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        _manager.distanceFilter = 10.0f;
        //[manager startUpdatingLocation];
        
        _error = nil;
        
        _timer = nil;
        _timeout = 10.0;
    }
    
    return self;
}


-(id)initWithTimeout:(double)timeoutValue 
{
    self = [self init];
    
    if(self)
    {
        self.timeout = timeoutValue;
    }
    
    return self;
}


-(void)setTimeout:(double)value 
{
    if(!_geocoding)
    {
        _timeout = MAX(1.0, value);
    }
}


-(void)locationManager:(CLLocationManager *)delegator didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    CLLocationCoordinate2D newLocationCoordinate = newLocation.coordinate;
    
    if(CLLocationCoordinate2DIsValid(newLocationCoordinate))
    {
        if(newLocationCoordinate.latitude != 0.0 || newLocationCoordinate.longitude != 0.0)
        {
            _location = newLocation;
        }
    } 
    else {
        _location = nil;
    }
    
    //NSLog(@"FCMapUserLocation didUpdateToLocation %f . %f", latitude, longitude);
    [delegator stopUpdatingLocation];
    
    [_timer invalidate];
    _timer = nil;
    
    _geocoding = FALSE;
    
    completion((_location != nil));
}


-(void)locationManager:(CLLocationManager *)delegator didFailWithError:(NSError *)error_arg
{
    //NSLog(@"FCMapUserLocation didFailWithError %f . %f", latitude, longitude);
    [delegator stopUpdatingLocation];
    
    _location = nil;
    
    _error = error_arg;
    
    [_timer invalidate];
    _timer = nil;
    
    _geocoding = FALSE;
    
    completion(FALSE);
}


-(void)startGeocode:(void (^)(BOOL success))completionHandler 
{
    if(_geocoding)
    {
        return;
    }
    
    _location = nil;
    
    _error = nil;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(timeoutGeocode) userInfo:nil repeats:FALSE];
    
    _geocoding = TRUE;
    
    completion = completionHandler;
    
    [_manager startUpdatingLocation];
}


-(void)timeoutGeocode 
{
    //NSLog(@"timeoutGeocode");
    [_manager stopUpdatingLocation];
    
    _location = nil;
    
    _error = [NSError errorWithDomain:kCLErrorDomain code:kCLErrorGeocodeCanceled userInfo:nil];
    
    [_timer invalidate];
    _timer = nil;
    
    _geocoding = FALSE;
    
    completion(FALSE);
}


-(void)stopGeocode 
{
    if(!_geocoding)
    {
        return;
    }
    
    [_manager stopUpdatingLocation];
    
    _location = nil;
    
    _error = nil;
    
    [_timer invalidate];
    _timer = nil;
    
    _geocoding = FALSE;
}


@end
