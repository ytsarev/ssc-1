module SSC
end

require 'handlers/all'
require 'argument_parser'
require 'yaml'

module SSC
  class Base
    def initialize(args)
      @args= ArgumentParser.new(args)
      @klass= @args.klass
      @options= get_config.merge(@args.options)
    end

    def run
      begin
        out= if @args.action_arguments.empty?
          @klass.new(@options).send(@args.action)
        else
          @klass.new(@options).send(@args.action, *@args.action_arguments)
        end
      rescue ArgumentError
        puts "Incorrect number of arguments provided"
        print_usage
      end

      print(out)
    end

    private

    def print_usage
      puts "TODO: Write usage file"
    end

    def print(output)
      puts output
    end

    def get_config
      config= if File.exist?(File.join(Dir.pwd, '.sscrc'))
        File.read(File.join(Dir.pwd, '.sscrc'))
      else
        ""
      end
      config = (YAML::load(config) || {}).symbolize_keys
    end
  end
end
