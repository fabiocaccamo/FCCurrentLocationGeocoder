Pod::Spec.new do |spec|
  spec.name         = 'FCCurrentLocationGeocoder'
  spec.version      = '1.1.7'
  spec.license      = { :type => 'UNLICENSE' }
  spec.homepage     = 'https://github.com/fabiocaccamo/FCCurrentLocationGeocoder'
  spec.authors      = { 'Fabio Caccamo' => 'fabio.caccamo@gmail.com' }
  spec.summary      = 'iOS Geocoder for forward geocode and reverse geocode user\'s current location using a block-based syntax. It can also be used to geocode the user\'s approximate location without asking for permission (GeoIP).'
  spec.source       = { :git => 'https://github.com/fabiocaccamo/FCCurrentLocationGeocoder.git', :tag => '1.1.7' }
  spec.source_files = 'FCCurrentLocationGeocoder/*.{h,m}'
  spec.platform     = :ios, '5.0'
  spec.framework    = 'Foundation', 'UIKit', 'CoreLocation'
  spec.requires_arc = true
  spec.dependency 'FCIPAddressGeocoder', '~> 1.0.0'
end
