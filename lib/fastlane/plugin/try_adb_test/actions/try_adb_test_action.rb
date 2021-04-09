module Fastlane
  module Actions
    require 'fastlane/action'

    class TryAdbTestAction < Action
      def self.run(params)
        clean_up(params)
        download_composer(params)
        run_tests(params)
      end

      def self.clean_up(params)
        FileUtils.rm_rf(params[:output_directory])
        FileUtils.mkdir_p(params[:output_directory])
      end

      def self.download_composer(params)
        composer_version = TryAdbTest::COMPOSER_VERSION
        composer_url = "https://jcenter.bintray.com/com/gojuno/composer/composer/#{composer_version}/composer-#{composer_version}.jar"
        curl = Curl.get(composer_url)
        File.open("#{params[:output_directory]}/composer.jar", 'w+') { |f| f.write(curl.body_str) }
      end

      def self.composer(params:,
                        instrumentation_arguments:,
                        output_directory:,
                        fail_build:)
        begin
          test_runner = params[:test_runner].empty? ? '' : "--test-runner #{params[:test_runner]}"
          extra_apks = params[:extra_apks].empty? ? '' : "--extra-apks #{params[:extra_apks]}"
          devices =
            if !params[:device_pattern].empty?
              "--device-pattern #{params[:device_pattern]}"
            elsif !params[:devices].empty?
              "--devices #{params[:devices]}"
            else
              ''
            end

          Actions.sh(
            "java -jar #{params[:output_directory]}/composer.jar" \
              " --apk #{params[:apk]}" \
              " --test-apk #{params[:test_apk]}" \
              " --output-directory #{output_directory}" \
              " --instrumentation-arguments #{instrumentation_arguments}" \
              " --verbose-output #{params[:verbose]}" \
              " --install-timeout #{params[:install_timeout]}" \
              " --fail-if-no-tests #{params[:fail_if_no_tests]}" \
              " --shard #{params[:shard]}" \
              " #{test_runner}" \
              " #{devices}" \
              " #{extra_apks}"
          )
        rescue
          raise FastlaneCore::UI.test_failure!('Tests have failed') if fail_build
        end
      end

      def self.run_tests(params)
        attempt = 1
        while attempt <= params[:try_count]
          FastlaneCore::UI.important("Getting started #{attempt} shot\n")
          output_directory = "#{params[:output_directory]}/#{attempt}_run"
          instrumentation_arguments =
            if @failed_tests.nil?
              params[:instrumentation_arguments]
            else
              "class #{@failed_tests.join(',')}"
            end
          fail_build = (attempt >= params[:try_count]) ? true : false
          composer(
            params: params,
            instrumentation_arguments: instrumentation_arguments,
            output_directory: output_directory,
            fail_build: fail_build
          )
          @failed_tests = scan_test_report(output_directory)
          break if @failed_tests.empty?

          attempt += 1
        end
      end

      def self.scan_test_report(output_directory)
        junit = "#{output_directory}/junit4-reports/"
        output_files = Dir.glob(File.join(junit, '**', '*')).select { |f| File.file?(f) }
        failed_tests = []
        output_files.each do |report|
          Nokogiri::XML(File.open(report)).root.xpath('//failure/..').each do |failure|
            test_name = failure.xpath('@name')
            class_name = failure.xpath('@classname')
            failed_tests << "#{class_name}##{test_name}"
          end
        end
        failed_tests
      end

      def self.authors
        ["alteral"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :apk,
                               description: "Either relative or absolute path to application apk that needs to be tested",
                                  optional: false,
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :test_apk,
                               description: "Either relative or absolute path to apk with tests",
                                  optional: false,
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :test_runner,
                               description: "Fully qualified name of test runner class you're using",
                                  optional: true,
                             default_value: '',
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :output_directory,
                               description: "Either relative or absolute path to directory for output: reports, files from devices and so on",
                                  optional: true,
                                   default_value: "fastlane/output",
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :instrumentation_arguments,
                               description: "Key-value pairs to pass to Instrumentation Runner",
                                  optional: true,
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :device_pattern,
                               description: "Connected devices/emulators that will be used to run tests against (example: 'emulator.+')",
                             default_value: '',
                                  optional: true,
                                 is_string: true,
                                      type: String,
                       conflicting_options: [:devices]),
          FastlaneCore::ConfigItem.new(key: :devices,
                               description: "Connected devices/emulators that will be used to run tests against (example: 'emulator-5554 emulator-5556')",
                             default_value: '',
                                  optional: true,
                                 is_string: true,
                                      type: String,
                       conflicting_options: [:device_pattern]),
          FastlaneCore::ConfigItem.new(key: :verbose,
                               description: "Either true or false to enable/disable verbose output for Composer",
                             default_value: false,
                                  optional: true,
                                 is_string: false,
                                      type: Boolean),
          FastlaneCore::ConfigItem.new(key: :shard,
                               description: "Enable/disable test sharding which statically shards tests between available devices/emulators",
                             default_value: true,
                                  optional: true,
                                 is_string: false,
                                      type: Boolean),
          FastlaneCore::ConfigItem.new(key: :fail_if_no_tests,
                               description: "Either true or false to enable/disable error on empty test suite",
                             default_value: true,
                                  optional: true,
                                 is_string: false,
                                      type: Boolean),
          FastlaneCore::ConfigItem.new(key: :extra_apks,
                               description: "Apks to be installed for utilities. What you would typically declare in gradle as androidTestUtil",
                             default_value: '',
                                  optional: true,
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :install_timeout,
                               description: "APK installation timeout in seconds. Applicable to both test APK and APK under test",
                             default_value: 120,
                                  optional: true,
                                 is_string: false,
                                      type: Integer),
          FastlaneCore::ConfigItem.new(key: :try_count,
                               description: "Number of times to try to get your tests green",
                                  optional: true,
                             default_value: 1,
                                 is_string: false,
                                      type: Integer)
        ]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
      end
    end
  end
end
