FCCurrentLocationGeocoder
=========================
Utility class for geocode / reverse-geocode the user current location.

##Requirements & Dependecies

- iOS >= 5.0
- CoreLocation Framework

##Usage
```objective-c
//geocoder creation
FCCurrentLocationGeocoder * geocoder;

geocoder = [FCCurrentLocationGeocoder geocoder];
//or
geocoder = [FCCurrentLocationGeocoder geocoderWithTimeout:10.0]; //10 seconds timeout
//or
geocoder = [[FCCurrentLocationGeocoder alloc] init];
//or
geocoder = [[FCCurrentLocationGeocoder alloc] initWithTimeout:5.0]; //5 seconds timeout
```
```objective-c
//geocoding
[geocoder geocode:^(BOOL success) {
    
    if(success)
    {
        //you can access the current location using 'geocoder.location'
    }
    else {
        //you can debug what's going wrong using: 'geocoder.error'
    }
}];
```
```objective-c
//reverse-geocoding
[geocoder reverseGeocode:^(BOOL success) {
    
    if(success)
    {
        //you can access the current location using 'geocoder.location'
        //you can access the current location placemarks using 'geocoder.locationPlacemarks'
        //you can access the current location first-placemark using 'geocoder.locationPlacemark'
    }
    else {
        //you can debug what's going wrong using: 'geocoder.error'
    }
}];
```
```objective-c
//check if geocoding
[geocoder isGeocoding]; //returns TRUE or FALSE
```
```objective-c
//cancel geocoding
[geocoder cancelGeocode];
```
