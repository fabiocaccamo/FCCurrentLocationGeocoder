FCCurrentLocationGeocoder
=========================

```objective-c
//create geocoder
FCCurrentLocationGeocoder * geocoder;

geocoder = [FCCurrentLocationGeocoder geocoder];
//or
geocoder = [FCCurrentLocationGeocoder geocoderWithTimeout:10.0]; //5 seconds timeout
//or
geocoder = [[FCCurrentLocationGeocoder alloc] init];
//or
geocoder = [[FCCurrentLocationGeocoder alloc] initWithTimeout:5.0]; //5 seconds timeout


//start geocoding
[geocoder startGeocode:^(BOOL success) {
    
    if(success)
    {
        //you can access the current location using 'geocoder.location'
    }
    else {
        //you can debug what's going wrong using: 'geocoder.error'
    }
}];


//stop geocoding
[geocoder stopGeocode];
```
