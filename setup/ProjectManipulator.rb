require 'xcodeproj'

module Pod

  class ProjectManipulator
    attr_reader :configurator, :xcodeproj_path, :platform, :remove_demo_target, :string_replacements, :prefix

    def self.perform(options)
      new(options).perform
    end

    def initialize(options)
      @xcodeproj_path = options.fetch(:xcodeproj_path)
      @configurator = options.fetch(:configurator)
      @platform = options.fetch(:platform)
      @remove_demo_target = options.fetch(:remove_demo_project)
      @prefix = options.fetch(:prefix)
    end

    def run
      @string_replacements = {
        "PROJECT_OWNER" => @configurator.user_name,
        "TODAYS_DATE" => @configurator.date,
        "TODAYS_YEAR" => @configurator.year,
        "PROJECTNAME" => @configurator.pod_name,
        "CPD" => @prefix
      }
      replace_internal_project_settings(project_folder)
      replace_internal_project_settings(carthage_project_folder)

      @project = Xcodeproj::Project.open(@xcodeproj_path)
      add_podspec_metadata(project_folder)
      remove_demo_project if @remove_demo_target
      @project.save

      rename_files(project_folder)
      rename_project_folder(project_folder)
      rename_files(carthage_project_folder)
      rename_project_folder(carthage_project_folder)
    end

    def add_podspec_metadata(project_folder)
      project_metadata_item = Xcodeproj::Project.open(project_folder).root_object.main_group.children.select { |group| group.name == "_" }.first
      project_metadata_item.new_file "../.gitignore"
      project_metadata_item.new_file "../.cocoadocs.yml"
      project_metadata_item.new_file "../.travis.yml"
      project_metadata_item.new_file "../" + @configurator.pod_name  + ".podspec"
      project_metadata_item.new_file "../LICENSE"
      project_metadata_item.new_file "../DEPLOY PROCESS.md"
      project_metadata_item.new_file "../CHANGELOG.md"
      project_metadata_item.new_file "../README.md"
      project_metadata_item.new_file "../checkBuild.command"
      project_metadata_item.new_file "../podCheck.command"
      project_metadata_item.new_file "../podPush.command"
    end

    def remove_demo_project
      app_project = @project.native_targets.find { |target| target.product_type == "com.apple.product-type.application" }
      test_target = @project.native_targets.find { |target| target.product_type == "com.apple.product-type.bundle.unit-test" }
      test_target.name = @configurator.pod_name + "_Tests"

      # Remove the implicit dependency on the app
      test_dependency = test_target.dependencies.first
      test_dependency.remove_from_project
      app_project.remove_from_project

      # Remove the build target on the unit tests
      test_target.build_configuration_list.build_configurations.each do |build_config|
        build_config.build_settings.delete "BUNDLE_LOADER"
      end

      # Remove the references in xcode
      project_app_group = @project.root_object.main_group.children.select { |group| group.display_name.end_with? @configurator.pod_name }.first
      project_app_group.remove_from_project

      # Remove the product reference
      product = @project.products.select { |product| product.path == @configurator.pod_name + "_Example.app" }.first
      product.remove_from_project

      # Replace the Podfile with a simpler one with only one target
      podfile_path = project_folder + "/Podfile"
      podfile_text = <<-RUBY
use_frameworks!
target '#{test_target.name}' do
  pod '#{@configurator.pod_name}', :path => '../'
  
  ${INCLUDED_PODS}
end
RUBY
      File.open(podfile_path, "w") { |file| file.puts podfile_text }
    end

    def project_folder
      File.dirname @xcodeproj_path
    end
    
    def carthage_project_folder
        directory = File.dirname @xcodeproj_path
        carthage_directory = File.expand_path("..", directory)
        carthage_directory + "/Carthage Project/"
    end

    def rename_files(project_folder)
      # shared schemes have project specific names
      scheme_path = project_folder + "/PROJECTNAME.xcodeproj/xcshareddata/xcschemes/"
      File.rename(scheme_path + "PROJECTNAME.xcscheme", scheme_path +  @configurator.pod_name + "-Example.xcscheme")

      # rename xcproject
      File.rename(project_folder + "/PROJECTNAME.xcodeproj", project_folder + "/" +  @configurator.pod_name + ".xcodeproj")

      unless @remove_demo_target
        # change app file prefixes
        ["CPDAppDelegate.h", "CPDAppDelegate.m", "CPDViewController.h", "CPDViewController.m"].each do |file|
          before = project_folder + "/PROJECTNAME/" + file
          next unless File.exists? before

          after = project_folder + "/PROJECTNAME/" + file.gsub("CPD", prefix)
          File.rename before, after
        end

        # rename project related files
        ["PROJECTNAME-Info.plist", "PROJECTNAME-Prefix.pch", "PROJECTNAME.h"].each do |file|
          before = project_folder + "/PROJECTNAME/" + file
          next unless File.exists? before

          after = project_folder + "/PROJECTNAME/" + file.gsub("PROJECTNAME", @configurator.pod_name)
          File.rename before, after
        end
      end

    end

    def rename_project_folder(project_folder)
      if Dir.exist? project_folder + "/PROJECTNAME"
        File.rename(project_folder + "/PROJECTNAME", project_folder + "/" + @configurator.pod_name)
      end
    end

    def replace_internal_project_settings(project_folder)
      Dir.glob(project_folder + "/**/**/**/**").each do |name|
        next if Dir.exists? name
        text = File.read(name)

        for find, replace in @string_replacements
            text = text.gsub(find, replace)
        end

        File.open(name, "w") { |file| file.puts text }
      end
    end

  end

end
