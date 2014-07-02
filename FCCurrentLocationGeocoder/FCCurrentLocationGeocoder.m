//
//  FCCurrentLocationGeocoder.m
//
//  Created by Fabio Caccamo on 11/08/12.
//  Copyright (c) 2012 Fabio Caccamo - http://www.fabiocaccamo.com/ - All rights reserved.
//

#import "FCCurrentLocationGeocoder.h"

@implementation FCCurrentLocationGeocoder


+(FCCurrentLocationGeocoder *)sharedGeocoder
{
    static FCCurrentLocationGeocoder *instance = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}


-(instancetype)init
{
    self = [super init];
    
    if(self)
    {
        _timer = nil;
        _timeoutErrorDelay = 15;
        _timeFilter = 5;
        
        _promptForAuthorization = YES;
        
        _geocoding = NO;
        
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
        _manager.desiredAccuracy = kCLLocationAccuracyBest;
        
        _bestLocation = nil;
        _bestLocationAttemptMaxDelay = 1;
        _bestLocationAttemptsCounter = 0;
        _bestLocationAttemptsLimit = 3;
        
        _reverse = NO;
        _reverseGeocoder = nil;
        
        _error = nil;
        
        [self _resetLocation];
    }
    
    return self;
}


-(void)cancelGeocode
{
    [self _cancelAndResetAllForced:NO];
}


-(BOOL)canGeocode
{
    return [FCCurrentLocationGeocoder canGeocodeIfCanPromptForAuthorization:_promptForAuthorization];
}


+(BOOL)canGeocode
{
    return [self canGeocodeIfCanPromptForAuthorization:YES];
}


+(BOOL)canGeocodeIfCanPromptForAuthorization:(BOOL)canPromptForAuthorization
{
    //http://stackoverflow.com/questions/4318708/checking-for-ios-location-services
    
    return ([CLLocationManager locationServicesEnabled] && (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) || (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) && canPromptForAuthorization)));
}


+(BOOL)canGeocodeWithoutPromptForAuthorization
{
    return [self canGeocodeIfCanPromptForAuthorization:NO];
}


-(void)geocode:(void (^)(BOOL success))completionHandler
{
    [self _startGeocodeWithReverse:NO andCompletionHandler:completionHandler];
}


-(void)reverseGeocode:(void (^)(BOOL success))completionHandler
{
    [self _startGeocodeWithReverse:YES andCompletionHandler:completionHandler];
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
        
        [self _completeGeocodeWithError:error];
    }
}


-(void)locationManager:(CLLocationManager *)delegator didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    [self locationManagerDidUpdateToLocation:newLocation];
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    
    [self locationManagerDidUpdateToLocation:newLocation];
}


-(void)locationManagerDidUpdateToLocation:(CLLocation *)newLocation
{
    if( newLocation == nil || newLocation.horizontalAccuracy < 0 )
    {
        return;
    }
    
    NSTimeInterval newLocationAge = -[newLocation.timestamp timeIntervalSinceNow];
    
    if( newLocationAge > 5.0 )
    {
        return;
    }
    
    CLLocationCoordinate2D newLocationCoordinate = newLocation.coordinate;
    
    if( !CLLocationCoordinate2DIsValid(newLocationCoordinate) || ( newLocationCoordinate.latitude == 0.0 && newLocationCoordinate.longitude == 0.0 ))
    {
        return;
    }
    
    if( _bestLocation == nil || newLocation.horizontalAccuracy < _bestLocation.horizontalAccuracy )
    {
        _bestLocation = newLocation;
    }
    
    //NSLog(@"FCCurrentLocationGeocoder didUpdateToLocation %f, %f ### horizontalAccuracy: %f", newLocationCoordinate.latitude, newLocationCoordinate.longitude, newLocation.horizontalAccuracy);
    
    if((_bestLocationAttemptMaxDelay * _bestLocationAttemptsLimit) < _timeoutErrorDelay || _timeoutErrorDelay <= 0 )
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationManagerDidUpdateToBestLocation) object:nil];
        [self performSelector:@selector(locationManagerDidUpdateToBestLocation) withObject:nil afterDelay:_bestLocationAttemptMaxDelay];
        
        if( _bestLocation.horizontalAccuracy > 100 )
        {
            _bestLocationAttemptsCounter++;
            
            //NSLog(@"FCCurrentLocationGeocoder bestLocationAttempts: %i / %i", _bestLocationAttemptsCounter, _bestLocationAttemptsLimit);
            
            if( _bestLocationAttemptsCounter < _bestLocationAttemptsLimit )
            {
                return;
            }
        }
    }
    
    [self locationManagerDidUpdateToBestLocation];
}


-(void)locationManagerDidUpdateToBestLocation
{
    _location = _bestLocation;
    
    [self _cancelAndResetForwardGeocode];
    [self _reverseGeocodeIfNeededOrCompleteGeocode];
}


-(void)_startGeocodeWithReverse:(BOOL)reverse andCompletionHandler:(void (^)(BOOL success))completionHandler
{
    if(!_geocoding && _location != nil && ([[_location.timestamp dateByAddingTimeInterval:_timeFilter] timeIntervalSinceNow] > 0)){
        _geocoding = YES;
        
        completion = completionHandler;
        
        //NSLog(@"FCCurrentLocationGeocoder useCache: YES");
        
        if( _reverse == reverse )
        {
            [self _completeGeocodeWithError:nil];
        }
        else {
            
            _reverse = reverse;
            
            if(!_reverse)
            {
                [self _resetLocationReverseInfo];
            }
            
            [self _reverseGeocodeIfNeededOrCompleteGeocode];
        }
    }
    else {
        
        [self _cancelAndResetAllForced:YES];
        
        _geocoding = YES;
        
        completion = completionHandler;
        
        //NSLog(@"FCCurrentLocationGeocoder useCache: NO");
        
        _reverse = reverse;
        
        if( [self canGeocode] )
        {
            if( _timeoutErrorDelay > 0 )
            {
                _timer = [NSTimer scheduledTimerWithTimeInterval:_timeoutErrorDelay target:self selector:@selector(_timeoutGeocode) userInfo:nil repeats:NO];
            }
            
            [_manager startUpdatingLocation];
        }
        else {
            
            [self _completeGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil]];
        }
    }
}


-(void)_cancelAndResetAllForced:(BOOL)forced
{
    if( _geocoding || forced ){
        _geocoding = NO;
        
        [self _cancelAndResetTimeoutErrorTimer];
        [self _cancelAndResetForwardGeocode];
        [self _cancelAndResetReverseGeocode];
        
        _error = nil;
        
        [self _resetLocation];
        
        //completion = nil;
    }
}


-(void)_cancelAndResetForwardGeocode
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationManagerDidUpdateToBestLocation) object:nil];
    
    if( _manager ){
        [_manager stopUpdatingLocation];
    }
    
    _bestLocation = nil;
    _bestLocationAttemptsCounter = 0;
}


-(void)_cancelAndResetReverseGeocode
{
    _reverse = NO;
    
    if( _reverseGeocoder != nil )
    {
        if( [_reverseGeocoder isGeocoding] ){
            [_reverseGeocoder cancelGeocode];
        }
        
        _reverseGeocoder = nil;
    }
}


-(void)_cancelAndResetTimeoutErrorTimer
{
    if( _timer != nil )
    {
        [_timer invalidate];
        _timer = nil;
    }
}


-(void)_completeGeocodeWithError:(NSError *)error
{
    if( _geocoding ){
        _geocoding = NO;
        
        [self _cancelAndResetTimeoutErrorTimer];
        [self _cancelAndResetForwardGeocode];
        [self _cancelAndResetReverseGeocode];
        
        _error = error;
        
        if(completion != nil)
        {
            if(_error != nil)
            {
                [self _resetLocation];
                
                completion( NO );
            }
            else {
                completion( YES );
            }
        }
    }
}


-(void)_resetLocation
{
    _location = nil;
    
    [self _resetLocationReverseInfo];
}


-(void)_resetLocationReverseInfo
{
    _locationPlacemarks = nil;
    _locationPlacemark = nil;
    _locationCountry = nil;
    _locationCountryCode = nil;
    _locationCity = nil;
    _locationZipCode = nil;
    _locationAddress = nil;
}


-(void)_reverseGeocodeIfNeededOrCompleteGeocode
{
    if( _reverse )
    {
        _reverseGeocoder = [[CLGeocoder alloc] init];
        [_reverseGeocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
            
            if(error != nil)
            {
                [self _completeGeocodeWithError:error];
            }
            else {
                
                if([placemarks count] > 0)
                {
                    _locationPlacemarks = placemarks;
                    _locationPlacemark = [_locationPlacemarks objectAtIndex:0];
                    _locationCountry = _locationPlacemark.country;
                    _locationCountryCode = _locationPlacemark.ISOcountryCode;
                    _locationCity = _locationPlacemark.locality;
                    _locationZipCode = _locationPlacemark.postalCode;
                    _locationAddress = [[_locationPlacemark.addressDictionary[ @"FormattedAddressLines" ] componentsJoinedByString:@", "] stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                    
                    [self _completeGeocodeWithError:nil];
                }
                else {
                    [self _completeGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorGeocodeFoundNoResult userInfo:nil]];
                }
            }
        }];
    }
    else {
        
        [self _completeGeocodeWithError:nil];
    }
}


-(void)_timeoutGeocode
{
    //NSLog(@"FCCurrentLocationGeocoder timeoutGeocode");
    
    [self _completeGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCFURLErrorTimedOut userInfo:nil]];
}


@end