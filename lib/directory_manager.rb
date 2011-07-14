module SSC
  module DirectoryManager

    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
      def included(base)
      end
    end

    module ClassMethods
      def create_appliance_directory(appliance_dir, username, password, appliance_id)
        FileUtils.mkdir_p(appliance_dir)
        FileUtils.mkdir_p(File.join(appliance_dir, 'files'))
        FileUtils.touch(File.join(appliance_dir, 'repositories'))
        FileUtils.touch(File.join(appliance_dir, 'software'))
        FileUtils.touch(File.join(appliance_dir, 'files/.file_list'))
        File.open(File.join(appliance_dir, '.sscrc'), 'w') do |file|
          file.write("username: #{username}\n"+
                     "password: #{password}\n"+
                     "appliance_id: #{appliance_id}")
        end
        File.join(Dir.pwd, appliance_dir)
      end

      def manage(local_source)
        self.class.class_variable_set('@@appliance_directory', Dir.pwd)
        if appliance_directory_valid?(Dir.pwd)
          file= File.join(Dir.pwd, local_source)
          self.class.class_variable_set('@@local_source', file) if File.exist?(file)
        end
      end

      private

      def appliance_directory_valid?(dir)
        config_file= File.join(dir, '.sscrc')
        File.exist?(config_file) && File.read(config_file).match(/appliance_id:\ *\d+/)
      end

    end

    module InstanceMethods

      def save(data)
        return false if data.nil? || data == []
        source= self.class.class_variable_get('@@local_source')
        written= []
        if source
          File.open(source, 'a+') do |f|
            written= write_to_file(f, data)
          end
        end
        written
      end

      def read
        source= self.class.class_variable_get('@@local_source')
        File.readlines(source).collect{|i| i.strip} if source
      end

      private

      def find_file_id(file_name) 
        file_list= File.join(self.class.class_variable_get('@@local_source'), '.file_list')
        parsed_file= YAML::load(File.read(file_list))
        if parsed_file["file_name"]
          id= parsed_file["file_name"]["id"] 
        else
          raise ArgumentError, "file not found"
        end
      end

      def full_local_file_path(file)
        full_path= File.join(self.class.class_variable_get('@@local_source'), file)
      end

      def show_file(file)
        full_path= full_local_file_path(file)
        if File.exist?(full_path)
          File.read(full_path)
        else
          raise ArgumentError, "file not found"
        end
      end

      def initiate_file(file_dir, file_name, id)
        source_file= File.join(file_dir, file_name)
        destination_file= full_local_file_path(file_name)
        if File.exist?(source_file)
          FileUtils.cp(source_file, destination_file)
          File.open(File.join(source, '.file_list'), 'a+') do  |f|
            file_entry= "\n#{destination_file}\n  source_dir: #{file_dir}\n  id: #{id}"
            write_to_file(f, [file_entry])
          end
          destination_file
        else
          raise ArgumentError, "File does not exist"
        end
      end

      def list_local_files
        source= self.class.class_variable_get('@@local_source')
        File.readlines(File.join(source, '.file_list')).collect{|i| i.strip} if source
      end

      def parse_file_list
        source= self.class.class_variable_get('@@local_source')
        file_list= File.read(File.join(source, '.file_list'))
        YAML::load(file_list)
      end

      def write_to_file(file, data)
        written= []
        existing_lines= file.readlines.collect{|i| i.strip}
        file.write("\n") if existing_lines.last != '' and existing_lines != []
        data.each do |line|
          unless existing_lines.include?( line )
            file.write(line+"\n") 
            written << line
          end
        end
      end

      def local_empty?
        File.read(self.class.class_variable_get('@@local_source')).strip == ""
      end

    end
  end
end
