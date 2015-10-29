require 'yaml'

module Awssh
  module Cache
    class Yaml < Base
      attr_reader :data

      def initialize(config)
        @config = config
        if @config.cache
          @file = File.expand_path(@config.cache)
        else
          @disabled = true
          @file = nil
        end
        @expires = @config.expires
        @data = load
      end

      def filter
        list = @data.inject([]) { |a, s| a << "#{s[:id]}|| #{s[:tags].inject([]) { |a, e| a << e.join(':') }.join(' ')}" }
        @terms.each do |key, value, opts|
          regex = key == 'name' ? /\sname:[^\s]*#{value}[^\s]*/ : /\s#{key}:#{value}/
          if opts[:inverse]
            found = list.grep(regex)
            list = list - found
          else
            list = list.grep(regex)
          end
        end
        list
      end

      private

      def load
        return {} if @disabled
        unless File.exists?(@file)
          @data = {}
          save
        end
        YAML.load_file(@file)
      end

      def save
        return if @disabled
        File.open(@file, "w+") { |f| f.write(@data.to_yaml) }
      end
    end
  end
end
