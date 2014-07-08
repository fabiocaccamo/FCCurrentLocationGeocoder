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
    if( key == nil )
    {
        return [self sharedGeocoder];
    }
    
    if( instances == nil ){
        instances = [NSMutableDictionary new];
    }
    
    FCCurrentLocationGeocoder *instance = [instances objectForKey:key];
    
    if( instance == nil ){
        instance = [self new];
        
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
        
        _canFallbackToGeoIP = NO;
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
        
        _geoIPURL = [NSURL URLWithString:@"http://freegeoip.net/json/"];
        _geoIPRequest = [NSURLRequest requestWithURL:_geoIPURL];
        _geoIPOperationQueue = [NSOperationQueue new];
    }
    
    return self;
}


-(void)cancelGeocode
{
    [self _cancelAndResetAllForced:NO];
}


+(void)cancelGeocode
{
    [[self sharedGeocoder] cancelGeocode];
}


-(BOOL)canGeocode
{
    return [FCCurrentLocationGeocoder canGeocodeIfCanPromptForAuthorization:_canPromptForAuthorization andIfCanFallbackToGeoIP:_canFallbackToGeoIP];
}


+(BOOL)canGeocode
{
    return [self canGeocodeIfCanPromptForAuthorization:YES andIfCanFallbackToGeoIP:NO];
}


+(BOOL)canGeocodeIfCanPromptForAuthorization:(BOOL)canPromptForAuthorization andIfCanFallbackToGeoIP:(BOOL)canFallbackToGeoIP
{
    //http://stackoverflow.com/questions/4318708/checking-for-ios-location-services
    
    return ([CLLocationManager locationServicesEnabled] && (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) || (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) && canPromptForAuthorization))) || canFallbackToGeoIP;
}


+(BOOL)canGeocodeWithoutPromptForAuthorization
{
    return [self canGeocodeIfCanPromptForAuthorization:NO andIfCanFallbackToGeoIP:NO];
}


-(void)geocode:(void (^)(BOOL success))completionHandler
{
    _reverseNeeded = NO;
    
    [self _startGeocodeWithCompletion:completionHandler];
}


+(void)geocode:(void (^)(BOOL))completionHandler
{
    [[self sharedGeocoder] geocode:completionHandler];
}


-(void)reverseGeocode:(void (^)(BOOL success))completionHandler
{
    _reverseNeeded = YES;
    
    [self _startGeocodeWithCompletion:completionHandler];
}


+(void)reverseGeocode:(void (^)(BOOL))completionHandler
{
    [[self sharedGeocoder] reverseGeocode:completionHandler];
}


-(void)locationManager:(CLLocationManager *)delegator didFailWithError:(NSError *)error
{
    if( error.code == kCLErrorLocationUnknown )
    {
        //If the location service is unable to retrieve a location right away, it reports a kCLErrorLocationUnknown error and keeps trying. In such a situation, you can simply ignore the error and wait for a new event.
        //http://developer.apple.com/library/ios/#documentation/CoreLocation/Reference/CLLocationManagerDelegate_Protocol/CLLocationManagerDelegate/CLLocationManagerDelegate.html#//apple_ref/occ/intfm/CLLocationManagerDelegate/locationManager:didFailWithError:
    }
    else {
        
        if( _canFallbackToGeoIP )
        {
            [self _cancelAndResetForwardGeocode];
            
            [self _forwardGeocodeWithGeoIP];
        }
        else {
            
            [self cancelGeocode];
            
            [self _completeGeocodeWithError:error];
        }
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
    [self _cancelAndResetForwardGeocodeWithGeoIP];
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


-(void)_cancelAndResetForwardGeocodeWithGeoIP
{
    if( _geoIPOperationQueue != nil ){
        [_geoIPOperationQueue cancelAllOperations];
    }
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


-(void)_forwardGeocode
{
    if( _timeoutErrorDelay > 0 )
    {
        _timeoutErrorTimer = [NSTimer scheduledTimerWithTimeInterval:_timeoutErrorDelay target:self selector:@selector(_timeoutGeocode) userInfo:nil repeats:NO];
    }
    
    if( [self canGeocode] )
    {
        [_locationManager startUpdatingLocation];
    }
    else if( _canFallbackToGeoIP )
    {
        [self _forwardGeocodeWithGeoIP];
    }
    else {
        
        [self _completeGeocodeWithError:[NSError errorWithDomain:kCLErrorDomain code:kCLErrorDenied userInfo:nil]];
    }
}


-(void)_forwardGeocodeWithGeoIP
{
    [self _cancelAndResetForwardGeocodeWithGeoIP];
    
    [NSURLConnection sendAsynchronousRequest:_geoIPRequest queue:_geoIPOperationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if( connectionError == nil )
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if( httpResponse.statusCode == 200 )
            {
                NSError *dataError = nil;
                NSDictionary *dataJSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&dataError];
                
                if( dataError == nil )
                {
                    CLLocationDegrees dataLatitude = [[dataJSON objectForKey:@"latitude"] doubleValue];
                    CLLocationDegrees dataLongitude = [[dataJSON objectForKey:@"longitude"] doubleValue];
                    CLLocation *dataLocation = [[CLLocation alloc] initWithLatitude:dataLatitude longitude:dataLongitude];
                    
                    [self _completeForwardGeocodeWithLocation:dataLocation];
                }
                else {
                    
                    [self _completeGeocodeWithError:dataError];
                }
            }
        }
        else {
            
            [self _completeGeocodeWithError:connectionError];
        }
    }];
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