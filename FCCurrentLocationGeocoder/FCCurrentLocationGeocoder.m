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
        _geocoding = NO;
        
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        
        _bestLocation = nil;
        _bestLocationAttempts = 0;
        
        _location = nil;
        _locationPlacemarks = nil;
        _locationPlacemark = nil;
        
        _reverse = NO;
        _geocoder = nil;
        
        _error = nil;
        
        _timer = nil;
        _timeout = 15.0;
        
        _prompt = YES;
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
    if(newLocation == nil)
    {
        return;
    }
    
    if(newLocation.horizontalAccuracy < 0)
    {
        return;
    }
    
    NSTimeInterval newLocationAge = -[newLocation.timestamp timeIntervalSinceNow];
    
    if(newLocationAge > 5.0)
    {
        return;
    }
    
    CLLocationCoordinate2D newLocationCoordinate = newLocation.coordinate;
    
    if(!CLLocationCoordinate2DIsValid(newLocationCoordinate))
    {
        return;
    }
    
    if(newLocationCoordinate.latitude == 0.0 && newLocationCoordinate.longitude == 0.0)
    {
        return;
    }
    
    if( _bestLocation == nil || newLocation.horizontalAccuracy < _bestLocation.horizontalAccuracy )
    {
        _bestLocation = newLocation;
    }
    
    //NSLog(@"FCCurrentLocationGeocoder didUpdateToLocation %f, %f ### accuracy: %f / %f", newLocationCoordinate.latitude, newLocationCoordinate.longitude, newLocation.horizontalAccuracy, delegator.desiredAccuracy);
    
    if(_bestLocation.horizontalAccuracy > 100)
    {
        _bestLocationAttempts++;
        
        if( _bestLocationAttempts < 3 )
        {
            return;
        }
    }
    
    [delegator stopUpdatingLocation];
    
    _location = _bestLocation;
    
    if(_reverse)
    {
        _geocoder = [[CLGeocoder alloc] init];
        [_geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
            
            if(error != nil)
            {
                [self _endGeocodeWithError:error];
            }
            else {
                
                if([placemarks count] > 0)
                {
                    _locationPlacemarks = placemarks;
                    _locationPlacemark = [_locationPlacemarks objectAtIndex:0];
                    
                    [self _endGeocodeWithError:nil];
                }
                else {
                    [self _endGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorGeocodeFoundNoResult userInfo:nil]];
                }
            }
        }];
    }
    else {
        [self _endGeocodeWithError:nil];
    }
}


-(void)locationManager:(CLLocationManager *)delegator didFailWithError:(NSError *)error
{
    if(error.code == kCLErrorLocationUnknown)
    {
        //If the location service is unable to retrieve a location right away, it reports a kCLErrorLocationUnknown error and keeps trying. In such a situation, you can simply ignore the error and wait for a new event.
        //http://developer.apple.com/library/ios/#documentation/CoreLocation/Reference/CLLocationManagerDelegate_Protocol/CLLocationManagerDelegate/CLLocationManagerDelegate.html#//apple_ref/occ/intfm/CLLocationManagerDelegate/locationManager:didFailWithError:
    }
    else {
        [self cancelGeocode];
        
        [self _endGeocodeWithError:error];
    }
}


-(void)_beginGeocodeWithReverse:(BOOL)reverse andCompletionHandler:(void (^)(BOOL success))completionHandler
{
    [self _cancelGeocode];
    
    completion = completionHandler;
    
    if([self canGeocode])
    {
        _geocoding = YES;
        
        _reverse = reverse;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:_timeout target:self selector:@selector(_timeoutGeocode) userInfo:nil repeats:NO];
        
        _error = nil;
        
        [_manager startUpdatingLocation];
    }
    else {
        [self _endGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil]];
    }
}


-(void)_cancelGeocode
{
    _geocoding = NO;
    
    [_manager stopUpdatingLocation];
    
    if(_geocoder)
    {
        if( [_geocoder isGeocoding] ){
            [_geocoder cancelGeocode];
        }
        
        _geocoder = nil;
    }
    
    if(_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    _reverse = NO;
    
    _bestLocation = nil;
    _bestLocationAttempts = 0;
    
    _location = nil;
    _locationPlacemarks = nil;
    _locationPlacemark = nil;
    
    _error = nil;
    
    completion = nil;
}


-(void)_endGeocodeWithError:(NSError *)error 
{
    _geocoder = nil;
    _geocoding = NO;
    
    _reverse = NO;
    
    if( _timer != nil ){
        [_timer invalidate];
        _timer = nil;
    }
    
    _error = error;
    
    if(_error != nil)
    {
        completion(NO);
    }
    else {
        completion(YES);
    }
}


-(void)_timeoutGeocode
{
    //NSLog(@"timeoutGeocode");
    
    [self cancelGeocode];
    
    [self _endGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCFURLErrorTimedOut userInfo:nil]];
}


-(void)cancelGeocode
{
    if(_geocoding)
    {
        [self _cancelGeocode];
    }
}


-(BOOL)canGeocode
{
    //http://stackoverflow.com/questions/4318708/checking-for-ios-location-services
    
    return ([CLLocationManager locationServicesEnabled] && (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) || (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) && [self canPromptForAuthorization])));
}


-(void)geocode:(void (^)(BOOL success))completionHandler
{
    [self _beginGeocodeWithReverse:NO andCompletionHandler:completionHandler];
}


-(void)reverseGeocode:(void (^)(BOOL))completionHandler
{
    [self _beginGeocodeWithReverse:YES andCompletionHandler:completionHandler];
}


@end