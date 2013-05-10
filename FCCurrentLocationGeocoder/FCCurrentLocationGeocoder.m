//
//  FCCurrentLocationGeocoder.m
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
        _locationPlacemarks = nil;
        _locationPlacemark = nil;
        
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        //manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        _manager.distanceFilter = 10.0f;
        //[manager startUpdatingLocation];
        
        _geocoder = nil;
        
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
    
    
    if(_location != nil)
    {
        if(_geocoder != nil)
        {
            [_geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
                
                if(error != nil)
                {
                    [self _finishGeocodeWithError:error];
                }
                else {
                    
                    if([placemarks count] > 0)
                    {
                        _locationPlacemarks = placemarks;
                        _locationPlacemark = [_locationPlacemarks objectAtIndex:0];
                        
                        [self _finishGeocodeWithError:nil];
                    }
                    else {
                        [self _finishGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorGeocodeFoundNoResult userInfo:nil]];
                    }
                }
                
            }];
        }
        else {
            [self _finishGeocodeWithError:nil];
        }
    }
    else {
        [self _finishGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorLocationUnknown userInfo:nil]];
    }
}


-(void)locationManager:(CLLocationManager *)delegator didFailWithError:(NSError *)error
{
    [self cancelGeocode];
    
    [self _finishGeocodeWithError:error];
}


-(void)_finishGeocodeWithError:(NSError *)error 
{
    _geocoder = nil;
    _geocoding = FALSE;
    
    [_timer invalidate];
    _timer = nil;
    
    _error = error;
    
    if(_error != nil)
    {
        completion(FALSE);
    }
    else {
        completion(TRUE);
    }
    
    /*
    if(!_geocoding)
    {
        completion = nil;
    }
    */
}


-(void)_timeoutGeocode
{
    //NSLog(@"timeoutGeocode");
    
    [self cancelGeocode];
    
    [self _finishGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCFURLErrorTimedOut userInfo:nil]];
}


-(void)cancelGeocode
{
    if(_geocoding){
        _geocoding = FALSE;
        
        [_manager stopUpdatingLocation];
        
        if(_geocoder)
        {
            if([_geocoder isGeocoding]){
                [_geocoder cancelGeocode];
            }
            
            _geocoder = nil;
        }
        
        _location = nil;
        _locationPlacemarks = nil;
        _locationPlacemark = nil;
        
        _error = nil;
        
        [_timer invalidate];
        _timer = nil;
    }
}


-(void)geocode:(void (^)(BOOL success))completionHandler
{
    [self cancelGeocode];
    
    completion = completionHandler;
    
    _geocoding = TRUE;
    
    _error = nil;
    _timer = [NSTimer scheduledTimerWithTimeInterval:_timeout target:self selector:@selector(_timeoutGeocode) userInfo:nil repeats:FALSE];
    
    [_manager startUpdatingLocation];
}


-(void)reverseGeocode:(void (^)(BOOL))completionHandler
{
    [self cancelGeocode];
    
    completion = completionHandler;
    
    _geocoding = TRUE;
    _geocoder = [[CLGeocoder alloc] init];
    
    _error = nil;
    _timer = [NSTimer scheduledTimerWithTimeInterval:_timeout target:self selector:@selector(_timeoutGeocode) userInfo:nil repeats:FALSE];
    
    [_manager startUpdatingLocation];
}


@end