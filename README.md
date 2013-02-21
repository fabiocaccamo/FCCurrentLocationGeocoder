FCCurrentLocationGeocoder
=========================

<pre><code>//create geocoder
FCCurrentLocationGeocoder * geocoder = [FCCurrentLocationGeocoder geocoder];
//or
FCCurrentLocationGeocoder * geocoder = [FCCurrentLocationGeocoder geocoderWithTimeout:5.0];
//or
FCCurrentLocationGeocoder * geocoder = [[FCCurrentLocationGeocoder alloc] init];
//or
FCCurrentLocationGeocoder * geocoder = [[FCCurrentLocationGeocoder alloc] initWithTimeout:5.0]; //5 seconds timeout


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
[geocoder stopGeocode];</code></pre>
