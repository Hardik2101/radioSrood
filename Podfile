platform :ios, '13.0'
source 'https://cdn.cocoapods.org/'

target 'Radio Srood' do
  use_frameworks!

  # Pods for Radio Srood
  pod 'Alamofire', '~> 5.6'
  pod 'AlamofireImage', '~> 4.1'
  pod 'SCLAlertView'
  pod 'OneSignal', '>= 2.6.2', '< 4.0'
  pod 'SWRevealViewController'
  pod 'VisualEffectView'
  pod 'Firebase/Core'
  pod 'Firebase/AdMob'
  pod 'AVPlayerViewController-Subtitles'
  pod 'SpotlightLyrics'
  pod 'GoogleUserMessagingPlatform'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'

        # ✅ Architecture exclusion based on system
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
end
