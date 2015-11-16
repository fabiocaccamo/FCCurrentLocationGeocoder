FCCurrentLocationGeocoder ![Pod version](http://img.shields.io/cocoapods/v/FCCurrentLocationGeocoder.svg) ![Pod platforms](http://img.shields.io/cocoapods/p/FCCurrentLocationGeocoder.svg) ![Pod license](http://img.shields.io/cocoapods/l/FCCurrentLocationGeocoder.svg)
=========================

iOS Geocoder on top of LocationManager and CLGeocoder for **forward geocode and reverse geocode user's current location** using a block-based syntax.

It can also be used to **geocode the user's approximate location (always country, almost always city) without asking for permission** (using a free GeoIP service).

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

###iOS 8
Since iOS 8 it is required to add `NSLocationWhenInUseUsageDescription` key to your `Info.plist` file. Value for this key will be a description of UIAlertView presented to user while asking for location  permission. See [Apple documentation](https://developer.apple.com/library/ios/documentation/corelocation/reference/CLLocationManager_Class/index.html#//apple_ref/occ/instm/CLLocationManager/requestWhenInUseAuthorization) for more info.

Basically all you need to do is to add single entry in your `Info.plist` file. Add key `NSLocationWhenInUseUsageDescription`, and select type `String`. The value you enter for this entry will be shown as text in UIAlertView presented to user first time you try to determine his location.
In the end it should look similar to this:

![Added entry to Info.plist](https://raw.githubusercontent.com/burczyk/FCCurrentLocationGeocoder/ios8-location-permission/assets/Info_plist.png)

###Code sample


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

##License
The MIT License (MIT)

Copyright (c) 2015 Fabio Caccamo - fabio.caccamo@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
