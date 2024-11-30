# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.0'

target 'Radio Srood' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Radio Srood
  
#  pod 'Alamofire', '~> 4.7'
#  pod 'SCLAlertView'
#  pod 'AlamofireImage', '~> 3.5'
#  pod 'OneSignal', '>= 2.6.2', '< 4.0'
#  pod 'SWRevealViewController'
#  pod 'VisualEffectView'
#  pod 'Firebase/Core'
#  pod 'Firebase/AdMob'
#  pod 'AVPlayerViewController-Subtitles'
#  pod 'SpotlightLyrics'
#  pod 'GoogleUserMessagingPlatform'
end



post_install do |installer|
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
         end
      end
   end
end
