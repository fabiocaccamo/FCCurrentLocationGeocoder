FCCurrentLocationGeocoder
=========================

<pre><code>FCCurrentLocationGeocoder * geocoder = [[FCCurrentLocationGeocoder alloc] init];
        
[geocoder startGeocode:^(BOOL success) {
    
    if(success)
    {
        //do something
    }
    else {
        //do something
    }
}];</code></pre>
