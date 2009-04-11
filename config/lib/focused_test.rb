#!/usr/local/bin/ruby
require 'optparse'

class FocusedTest
  def initialize(args)
    parse args
  end

  def parse(args)
    @file_path = nil
    @line_number = 0
    @rspec_version = ""
    @show_backtrace = false
    options = OptionParser.new do |o|
      o.on('-f', '--filepath=FILEPATH', String, "File to run test on") do |path|
        @file_path = path
      end

      o.on('-l', '--linenumber=LINENUMBER', Integer, "Line of the test") do |line|
        @line_number = line
      end
      o.on('-r', '--rspec-version=VERSION', String, "Version of Rspec to Run") do |version|
        @rspec_version = "_#{version}_"
      end

      o.on('-b', '--backtrace', String, "Show the backtrace of errors") do
        @show_backtrace = true
      end

      o.on('-X', '--drb', String, "Run examples via DRb.") do
        @drb = true
      end
    end
    options.order(ARGV)
  end

  def run_test(content)
    current_line = 0
    current_method = nil
    
    content.split("\n").each do |line|
      break if current_line > @line_number
      if /def +(test_[A-Za-z_!?]*)/ =~ line
        current_method = Regexp.last_match(1)
      end
      current_line += 1
    end
    
    require @file_path
    runner = Test::Unit::AutoRunner.new(false) do |runner|
      runner.filters << proc{|t| current_method == t.method_name ? true : false}
    end
    runner.run
    puts "Running '#{current_method}' in file #{@file_path}"
  end

  def run_example
    cmd = nil
    ["script/spec", "vendor/plugins/rspec/bin/spec"].each do |spec_file|
      if File.exists?(spec_file)
        cmd = spec_file
        break
      end
    end
    cmd = (RUBY_PLATFORM =~ /[^r]win/) ? "spec.cmd" : "spec" unless cmd
    cmd << "#{@rspec_version} --line #{@line_number} #{@file_path}"
    cmd << ' --backtrace' if @show_backtrace
    cmd << ' --drb' if @drb
    system cmd 
  end

  def run
    test_type = nil
    current_method = nil

    content = IO.read(@file_path)
#ActionController::IntegrationTest
#Test::Unit::TestCase
    if content =~ /class .*Test < (.*TestCase|ActionController::IntegrationTest)/
      run_test content
    else
      run_example
    end
  end
end

if $0 == __FILE__
  FocusedTest.new(ARGV).run
end

