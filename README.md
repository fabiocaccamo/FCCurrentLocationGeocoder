FCCurrentLocationGeocoder
=========================

iOS Class on top of LocationManager and CLGeocoder for **geocode / reverse-geocode user current location** using a block-based syntax.

##Requirements & Dependecies
- iOS >= 5.0
- ARC enabled
- CoreLocation Framework
- [FCIPAddressGeocoder](https://github.com/fabiocaccamo/FCIPAddressGeocoder)

##Installation

####CocoaPods:
`pod 'FCCurrentLocationGeocoder'`

####Manual install:
- Copy `FCCurrentLocationGeocoder.h` and `FCCurrentLocationGeocoder.m` to your project
- Manual install [FCIPAddressGeocoder](https://github.com/fabiocaccamo/FCIPAddressGeocoder/#manual-install)

##Usage
```objective-c
//you can use the shared instance
[FCCurrentLocationGeocoder sharedGeocoder];

//you can also use as many shared instances as you need
[FCCurrentLocationGeocoder sharedGeocoderForKey:@"yourKey"];

//or create a new geocoder and set options
FCCurrentLocationGeocoder *geocoder = [FCCurrentLocationGeocoder new];
geocoder.canPromptForAuthorization = NO; //(optional, default value is YES)
geocoder.canUseIPAddressAsFallback = YES; //(optional, default value is NO. very useful if you need just the approximate user location, such as current country, without asking for permission)
geocoder.timeFilter = 30; //(cache duration, optional, default value is 5 seconds)
geocoder.timeoutErrorDelay = 10; //(optional, default value is 15 seconds)

```
```objective-c
//check if location services are enabled and the current app is authorized or could be authorized
[geocoder canGeocode]; //returns YES or NO
```
```objective-c
//current-location forward-geocoding
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
        //you can access the current location country using 'geocoder.locationCountry'
        //you can access the current location country-code using 'geocoder.locationCountryCode'
        //you can access the current location city using 'geocoder.locationCity'
        //you can access the current location zip-code using 'geocoder.locationZipCode'
        //you can access the current location address using 'geocoder.locationAddress'
    }
    else {
        //you can debug what's going wrong using: 'geocoder.error'
    }
}];
```
```objective-c
//check if geocoding
[geocoder isGeocoding]; //returns YES or NO
```
```objective-c
//cancel geocoding
[geocoder cancelGeocode];
```

Enjoy :)
