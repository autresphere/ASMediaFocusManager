Pod::Spec.new do |s|
  s.name = "ASMediaFocusManager"
  s.version = "0.7"
  s.license = 'MIT'
  s.summary = "Animate your iOS image and video views to fullscreen on a simple tap."
  s.authors = {
    "Philippe Converset" => "pconverset@autresphere.com"
  }
  s.homepage = "https://github.com/autresphere/ASMediaFocusManager"
  s.source = {
    :git => "https://github.com/autresphere/ASMediaFocusManager.git",
    :tag => s.version.to_s
  }
  s.platform = :ios, '6.0'
  s.source_files = 'ASMediaFocusManager/*.{h,m}'
  s.resources = ['ASMediaFocusManager/*.xib', 'ASMediaFocusManager/Resources/*.png']
  s.frameworks = 'UIKit', 'Foundation', 'CoreGraphics', 'AVFoundation'
  s.requires_arc = true
  s.dependency 'ASBPlayerScrubbing', '~> 0.1'
end