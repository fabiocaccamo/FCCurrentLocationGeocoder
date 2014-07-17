Pod::Spec.new do |spec|
  spec.name         = 'FCCurrentLocationGeocoder'
  spec.version      = '1.1.6'
  spec.license      = { :type => 'UNLICENSE' }
  spec.homepage     = 'https://github.com/fabiocaccamo/FCCurrentLocationGeocoder'
  spec.authors      = { 'Fabio Caccamo' => 'fabio.caccamo@gmail.com' }
  spec.summary      = 'iOS Class for forward geocode and reverse geocode user current location using a block-based syntax. It can be used also to know the user approximate location (always country, almost always city) without asking for permission (GeoIP).'
  spec.source       = { :git => 'https://github.com/fabiocaccamo/FCCurrentLocationGeocoder.git', :tag => '1.1.6' }
  spec.source_files = 'FCCurrentLocationGeocoder/*.{h,m}'
  spec.platform     = :ios, '5.0'
  spec.framework    = 'Foundation', 'UIKit', 'CoreLocation'
  spec.requires_arc = true
  spec.dependency 'FCIPAddressGeocoder', '~> 1.0.0'
end
