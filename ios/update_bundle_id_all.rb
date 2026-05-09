require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

project.targets.each do |target|
  suffix = case target.name
           when 'Runner'
             ''
           when 'ImageNotification'
             '.ImageNotification'
           when 'TrembleRadarWidgetExtension'
             '.TrembleRadarWidget'
           when 'RunnerTests'
             '.RunnerTests'
           else
             ''
           end

  target.build_configurations.each do |config|
    base_id = if config.name.end_with?('-prod')
                'tremble.dating.app'
              else
                'com.pulse.dev.aleks'
              end
    
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{base_id}#{suffix}"
  end
end

project.save
puts "Bundle IDs updated for all targets and configurations."
