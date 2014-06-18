FCCurrentLocationGeocoder
=========================

iOS Class on top of LocationManager and CLGeocoder for **geocode/reverse-geocode user current location** using a block-based syntax.

##Requirements & Dependecies
- iOS >= 5.0
- ARC enabled
- CoreLocation Framework

##Installation

####CocoaPods:
`pod 'FCCurrentLocationGeocoder'`

####Manual install:
Copy `FCCurrentLocationGeocoder.h` and `FCCurrentLocationGeocoder.m` to your project.

##Usage
```objective-c
//geocoder initialization
FCCurrentLocationGeocoder * geocoder = [FCCurrentLocationGeocoder geocoder];
geocoder.timeout = 5; //(optional) you can set timeout-error timeout
```
```objective-c
//current-location forward geocoding
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
//current-location reverse-geocoding
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

Enjoy :)
