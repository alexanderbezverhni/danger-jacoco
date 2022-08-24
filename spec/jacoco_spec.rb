# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/BlockLength

require File.expand_path('spec_helper', __dir__)

module Danger
  describe Danger::DangerJacoco do
    it 'should be a plugin' do
      expect(Danger::DangerJacoco.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @my_plugin = @dangerfile.jacoco

        modified_files = ['src/java/com/example/CachedRepository.java']
        added_files = ['src/java/io/sample/UseCase.java']

        allow(@dangerfile.git).to receive(:modified_files).and_return(modified_files)
        allow(@dangerfile.git).to receive(:added_files).and_return(added_files)
      end

      it :report do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_class_coverage_map = { 'com/example/CachedRepository' => 100 }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:errors]).to eq(['Total coverage of 32.9%. Improve this to at least 50%',
                                                          'Class coverage is below minimum. Improve to at least 0%'])
        expect(@dangerfile.status_report[:markdowns][0].message).to include('### JaCoCo Code Coverage 32.9% :warning:')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| Class | Covered | Required | Status |')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('|:---|:---:|:---:|:---:|')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 100% | :warning: |')
      end

      it 'test regex class coverage' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_class_coverage_map = { '.*Repository' => 60 }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 60% | :warning: |')
      end

      it 'test with package coverage' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_package_coverage_map = { 'com/example/' => 70 }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 70% | :warning: |')
      end

      it 'test with bigger overlapped package coverage' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_package_coverage_map = {
          'com/example/' => 70,
          'com/' => 90
        }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 70% | :warning: |')
      end

      it 'test with lower overlapped package coverage' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_package_coverage_map = {
          'com/example/' => 77,
          'com/' => 30
        }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 77% | :warning: |')
      end

      it 'test with overlapped package coverage and bigger class coverage' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_package_coverage_map = {
          'com/example/' => 77,
          'com/' => 30
        }
        @my_plugin.minimum_class_coverage_map = { 'com/example/CachedRepository' => 100 }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 100% | :warning: |')
      end

      it 'test with overlapped package coverage and lower class coverage' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_package_coverage_map = {
          'com/example/' => 90,
          'com/' => 85
        }
        @my_plugin.minimum_class_coverage_map = { 'com/example/CachedRepository' => 80 }

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 80% | :warning: |')
      end

      it 'checks modified files when "only_check_new_files" attribute is false' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_c.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.only_check_new_files = false

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('### JaCoCo Code Coverage 55.59% :white_check_mark:')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| Class | Covered | Required | Status |')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('|:---|:---:|:---:|:---:|')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 0% | :white_check_mark: |')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `io/sample/UseCase` | 66% | 0% | :white_check_mark: |')
      end

      it 'defaults "only_check_new_files" attribute to false' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_c.xml"

        @my_plugin.minimum_project_coverage_percentage = 50

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `com/example/CachedRepository` | 50% | 0% | :white_check_mark: |')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `io/sample/UseCase` | 66% | 0% | :white_check_mark: |')
      end

      it 'does _not_ check modified files when "only_check_new_files" attribute is true' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_c.xml"

        @my_plugin.minimum_project_coverage_percentage = 50
        @my_plugin.minimum_class_coverage_percentage = 70
        @my_plugin.only_check_new_files = true

        @my_plugin.report path_a

        expect(@dangerfile.status_report[:markdowns][0].message).to include('### JaCoCo Code Coverage 55.59% :white_check_mark:')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| Class | Covered | Required | Status |')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('|:---|:---:|:---:|:---:|')
        expect(@dangerfile.status_report[:markdowns][0].message).to include('| `io/sample/UseCase` | 66% | 70% | :warning: |')
        expect(@dangerfile.status_report[:markdowns][0].message).not_to include('com/example/CachedRepository')
      end

      it 'adds a link to report' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_class_coverage_percentage = 80
        @my_plugin.minimum_project_coverage_percentage = 50

        @my_plugin.report(path_a, 'http://test.com/')

        expect(@dangerfile.status_report[:markdowns][0].message).to include('| [`com/example/CachedRepository`](http://test.com/com.example/CachedRepository.html) | 50% | 80% | :warning: |')
      end

      it 'When option "fail_no_coverage_data_found" is set to optionally fail, it doesn\'t fail the execution' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_a.xml"

        @my_plugin.minimum_class_coverage_percentage = 80
        @my_plugin.minimum_project_coverage_percentage = 50

        expect { @my_plugin.report(path_a, fail_no_coverage_data_found: true) }.to_not raise_error(RuntimeError)
      end

      it 'When option "fail_no_coverage_data_found" is not set, the execution fails on empty data' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_b.xml"

        @my_plugin.minimum_class_coverage_percentage = 80
        @my_plugin.minimum_project_coverage_percentage = 50

        expect { @my_plugin.report path_a }.to raise_error(RuntimeError)
      end

      it 'When option "fail_no_coverage_data_found" is set to optionally fail, the execution fails on empty data' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_b.xml"

        @my_plugin.minimum_class_coverage_percentage = 80
        @my_plugin.minimum_project_coverage_percentage = 50

        expect { @my_plugin.report path_a, fail_no_coverage_data_found: true }.to raise_error(RuntimeError)
      end

      it 'When option "fail_no_coverage_data_found" is set to optionally warn (not fail), the execution doesn\'t fail on empty data' do
        path_a = "#{File.dirname(__FILE__)}/fixtures/output_b.xml"

        @my_plugin.minimum_class_coverage_percentage = 80
        @my_plugin.minimum_project_coverage_percentage = 50

        expect { @my_plugin.report path_a, fail_no_coverage_data_found: false }.to_not raise_error(RuntimeError)
      end
    end
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/BlockLength
