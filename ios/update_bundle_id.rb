require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  if target.name == 'Runner'
    target.build_configurations.each do |config|
      if config.name.end_with?('-dev')
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.pulse.dev.aleks'
      elsif config.name.end_with?('-prod')
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'tremble.dating.app'
      else
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.pulse.dev.aleks'
      end
    end
  end
end

project.save
puts "Bundle IDs updated for dev and prod configurations."
