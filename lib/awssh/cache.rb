require 'ostruct'

module Awssh
  class Cache
    class << self
      def load(file)
        @instance = new(file)
      end

      def instance
        raise 'cache not loaded?' unless @instance.data
        @instance
      end
    end

    attr_reader :data

    def initialize(file, expires)
      if file
        @file = File.expand_path(file)
      else
        @disabled = true
        @file = nil
      end
      @expires = expires
      @data = load
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
      File.open(@file, "w+") {|f| f.write(@data.to_yaml)}
    end
  end
end