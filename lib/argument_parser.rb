module SSC

  class UnkownOptionError < StandardError
  end

  class ArgumentParser
  
    include Handler

    attr_reader :klass, :action, :options, :action_arguments

    def initialize(args)
      @klass  = get_class(args[0])
      @action = get_action(args[1])
      @action_arguments, @options = get_options(args[2..-1])
    end

    private

    def get_class(arg)
      case arg
      when 'appliance'
        Appliance
      when 'repository'
        Repository
      when 'package'
        Package
      when 'file'
        File
      when 'template'
        Template
      else
        raise UnkownOptionError
      end
    end

    def get_action(arg)
      if @klass.new.respond_to?(arg.to_sym)
        arg
      else
        raise UnkownOptionError
      end
    end

    def get_options(args)
      options = {}; last_key= nil; action_arguments= []
      args.each do |arg|
        if arg.match(/^-/)
          last_key= arg.gsub(/^-+/, '')
          options.merge!({last_key.to_sym => true})
        else
          if last_key
            options.merge!({last_key.to_sym => arg}) 
          else
            action_arguments << arg
          end
        end
      end
      number_of_arguments= @klass.new.method(@action).arity
      [action_arguments[0..number_of_arguments], options]
    end
  end
end