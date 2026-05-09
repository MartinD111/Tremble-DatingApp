require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def duplicate_configs(configurable, project)
  configs_to_add = []
  configurable.build_configurations.each do |config|
    if ['Debug', 'Release', 'Profile'].include?(config.name)
      # Duplicate for dev
      dev_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
      dev_config.name = "#{config.name}-dev"
      dev_config.build_settings = config.build_settings.clone
      dev_config.base_configuration_reference = config.base_configuration_reference
      configs_to_add << dev_config

      # Duplicate for prod
      prod_config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
      prod_config.name = "#{config.name}-prod"
      prod_config.build_settings = config.build_settings.clone
      prod_config.base_configuration_reference = config.base_configuration_reference
      configs_to_add << prod_config
    end
  end
  
  configs_to_add.each do |c|
    configurable.build_configurations << c
  end
end

# Add to Project
duplicate_configs(project, project)

# Add to all targets
project.targets.each do |target|
  duplicate_configs(target, project)
end

project.save
puts "Successfully duplicated build configurations for flavors!"
