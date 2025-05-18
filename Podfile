platform :ios, '18.0'
target 'BeaconNext' do
  pod 'TencentNavKit', '6.12.0'
  pod 'libwebp'
end

post_install do
  |installer| installer.pods_project.targets.each do
    |t| t.build_configurations.each do
      |config| config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
end
