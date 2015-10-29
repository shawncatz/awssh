require 'ostruct'

module Awssh
  module Cache
    class << self
      def create(name, config)
        puts "create: #{name} #{config}"
        puts config.inspect
        k = get_class(name.to_s)
        @instance = k.new(config)
      end

      def instance
        raise 'cache not loaded?' unless @instance && @instance.data
        @instance
      end

      def get_class(name)
        "Awssh::Cache::#{name.camelize}".constantize
      end
    end

    class Base
      attr_reader :data

      def initialize(config)

      end

      def write(key, value)
        time = Time.now.to_i
        data = {time: time, value: value}
        @data[key] = data
        save
      end

      def read(key)
        @data[key][:value]
      end

      def fetch(key, force)
        if force || @disabled
          diff = Time.now.to_i
        else
          time = @data[key] ? @data[key][:time] : 0
          diff = Time.now.to_i - time
        end
        if diff > @expires
          value = yield
          write(key, value)
          return value
        else
          read(key)
        end
      end

      protected

      def load
        raise 'override in subclass'
      end

      def save
        raise 'override in subclass'
      end
    end
  end
end
