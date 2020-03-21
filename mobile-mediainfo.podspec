#
# Be sure to run `pod lib lint mobile-mediainfo.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'mobile-mediainfo'
  s.version          = '19.09'
  s.summary          = 'MediaInfo for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/chaoskyme/mobile-mediainfo'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'chaoskyme' => 'chaosky.me@gmail.com' }
  s.source           = { :git => 'https://github.com/chaoskyme/mobile-mediainfo.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'mobile-mediainfo/include/**/*'
  # s.public_header_files = 'Pod/include/**/*.h'
  s.vendored_libraries = 'mobile-mediainfo/lib/**/*.a'
  s.frameworks = 'Foundation', 'CoreFoundation'
  s.libraries = 'z', 'c++'
  s.user_target_xcconfig = {'GCC_PREPROCESSOR_DEFINITIONS' => ["UNICODE=1", "_UNICODE=1"]}
end
