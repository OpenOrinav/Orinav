platform :ios, '12.4'
target 'BeaconNext' do
  pod 'AMapLocation-NO-IDFA'
  pod 'AMapSearch-NO-IDFA'
  pod 'AMap2DMap-NO-IDFA'
end

post_install do |installer| installer.pods_project.targets.each do |t| t.build_configurations.each do |config| config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.4' end end end
