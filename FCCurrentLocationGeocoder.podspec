Pod::Spec.new do |spec|
  spec.name         = 'FCCurrentLocationGeocoder'
  spec.version      = '1.1.0'
  spec.license      = { :type => 'UNLICENSE' }
  spec.homepage     = 'https://github.com/fabiocaccamo/FCCurrentLocationGeocoder'
  spec.authors      = { 'Fabio Caccamo' => 'fabio.caccamo@gmail.com' }
  spec.summary      = 'iOS Class for geocode / reverse-geocode user current location using a block-based syntax.'
  spec.source       = { :git => 'https://github.com/fabiocaccamo/FCCurrentLocationGeocoder.git', :tag => '1.1.0' }
  spec.source_files = 'FCCurrentLocationGeocoder/*.{h,m}'
  spec.platform     = :ios, '5.0'
  spec.framework    = 'Foundation', 'UIKit', 'CoreLocation'
  spec.requires_arc = true
end
