FCCurrentLocationGeocoder
=========================

<pre><code>FCCurrentLocationGeocoder * geocoder = [[FCCurrentLocationGeocoder alloc] initWithTimeout:5.0]; //5 seconds timeout

geocoder
[geocoder startGeocode:^(BOOL success) {
    
    if(success)
    {
        //you can access the current location using 'geocoder.location'
    }
    else {
        //you can debug what's going wrong using: 'geocoder.error'
    }
}];</code></pre>
