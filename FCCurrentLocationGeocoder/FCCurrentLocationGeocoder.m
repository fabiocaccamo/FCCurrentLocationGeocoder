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


static NSMutableDictionary *instances = nil;


+(FCCurrentLocationGeocoder *)sharedGeocoderForKey:(NSString *)key
{
    if( instances == nil ){
        instances = [NSMutableDictionary new];
    }
    
    FCCurrentLocationGeocoder *instance = [instances objectForKey:key];
    
    if( instance == nil ){
        instance = [FCCurrentLocationGeocoder new];
        
        [instances setObject:instance forKey:key];
    }
    
    return instance;
}


-(instancetype)init
{
    self = [super init];
    
    if( self )
    {
        _timeoutErrorTimer = nil;
        _timeoutErrorDelay = 15;
        _timeFilter = 5;
        
        _canPromptForAuthorization = YES;
        
        _geocoding = NO;
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        _bestLocation = nil;
        _bestLocationAttemptTimeoutTimer = nil;
        _bestLocationAttemptTimeout = 1;
        _bestLocationAttemptsCounter = 0;
        _bestLocationAttemptsLimit = 3;
        
        _reverseNeeded = NO;
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
    return [FCCurrentLocationGeocoder canGeocodeIfCanPromptForAuthorization:_canPromptForAuthorization];
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
    _reverseNeeded = NO;
    
    [self _startGeocodeWithCompletion:completionHandler];
}
}


-(void)reverseGeocode:(void (^)(BOOL success))completionHandler
{
    _reverseNeeded = YES;
    
    [self _startGeocodeWithCompletion:completionHandler];
}
}


-(void)locationManager:(CLLocationManager *)delegator didFailWithError:(NSError *)error
{
    if( error.code == kCLErrorLocationUnknown )
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
    
    if((_bestLocationAttemptTimeout * _bestLocationAttemptsLimit) < _timeoutErrorDelay || _timeoutErrorDelay <= 0 )
    {
        if( _bestLocationAttemptTimeoutTimer != nil ){
            [_bestLocationAttemptTimeoutTimer invalidate];
            _bestLocationAttemptTimeoutTimer = nil;
        }
        
        _bestLocationAttemptTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:_bestLocationAttemptTimeout target:self selector:@selector(locationManagerDidUpdateToBestLocation) userInfo:nil repeats:NO];
        
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
    
    [self _completeForwardGeocodeWithLocation:_bestLocation];
}


-(void)_startGeocodeWithCompletion:(void (^)(BOOL success))completionHandler
{
    if( _error != nil )
    {
        [self _cancelAndResetAllForced:YES];
    }
    else {
        
        [self _cancelAndResetAllForced:NO];
    }
    
    _geocoding = YES;
    
    _completionHandler = completionHandler;
    
    BOOL useCache = (_location != nil && ([[_location.timestamp dateByAddingTimeInterval:_timeFilter] timeIntervalSinceNow] > 0));
    
    //NSLog(@"FCCurrentLocationGeocoder useCache: %@", useCache ? @"YES" : @"NO");
    
    if( useCache )
    {
        if( _reverseNeeded && _locationPlacemark == nil )
        {
            [self _reverseGeocode];
        }
        else {
            
            [self _completeGeocodeWithError:nil];
        }
    }
    else {
        
        [self _forwardGeocode];
    }
}


-(void)_cancelAndResetAllForced:(BOOL)forced
{
    if( _geocoding || forced ){
        _geocoding = NO;
        
        [self _cancelAndResetAsyncOperations];
        
        _error = nil;
        
        [self _resetLocation];
    }
}


-(void)_cancelAndResetAsyncOperations
{
    [self _cancelAndResetTimeoutErrorTimer];
    [self _cancelAndResetForwardGeocode];
    [self _cancelAndResetReverseGeocode];
}


-(void)_cancelAndResetForwardGeocode
{
    if( _bestLocationAttemptTimeoutTimer != nil ){
        [_bestLocationAttemptTimeoutTimer invalidate];
        _bestLocationAttemptTimeoutTimer = nil;
    }
    
    if( _locationManager != nil ){
        [_locationManager stopUpdatingLocation];
    }
    
    _bestLocation = nil;
    _bestLocationAttemptsCounter = 0;
}


-(void)_cancelAndResetReverseGeocode
{
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
    if( _timeoutErrorTimer != nil )
    {
        [_timeoutErrorTimer invalidate];
        _timeoutErrorTimer = nil;
    }
}


-(void)_completeForwardGeocodeWithLocation:(CLLocation *)location
{
    _location = location;
    
    [self _cancelAndResetForwardGeocode];
    [self _reverseGeocodeIfNeededOrCompleteGeocode];
}


-(void)_completeGeocodeWithError:(NSError *)error
{
    if( _geocoding ){
        _geocoding = NO;
        
        [self _cancelAndResetAsyncOperations];
        
        _error = error;
        
        if( _completionHandler != nil )
        {
            if( _error != nil )
            {
                [self _resetLocation];
                
                _completionHandler( NO );
            }
            else {
                
                _completionHandler( YES );
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


-(void)_reverseGeocode
{
    [self _cancelAndResetReverseGeocode];
    
    _reverseGeocoder = [[CLGeocoder alloc] init];
    [_reverseGeocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if( error != nil )
        {
            [self _completeGeocodeWithError:error];
        }
        else {
            
            if( [placemarks count] > 0 )
            {
                _locationPlacemarks = placemarks;
                _locationPlacemark = [_locationPlacemarks objectAtIndex:0];
                _locationCountry = _locationPlacemark.country;
                _locationCountryCode = _locationPlacemark.ISOcountryCode;
                _locationCity = _locationPlacemark.locality;
                _locationZipCode = _locationPlacemark.postalCode;
                _locationAddress = [[_locationPlacemark.addressDictionary[@"FormattedAddressLines"] componentsJoinedByString:@", "] stringByReplacingOccurrencesOfString:@"  " withString:@" "];
                
                [self _completeGeocodeWithError:nil];
            }
            else {
                
                [self _completeGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorGeocodeFoundNoResult userInfo:nil]];
            }
        }
    }];
}


-(void)_reverseGeocodeIfNeededOrCompleteGeocode
{
    if( _reverseNeeded )
    {
        [self _reverseGeocode];
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