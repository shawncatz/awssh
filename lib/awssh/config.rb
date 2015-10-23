require 'ostruct'
require 'yaml'

module Awssh
  class Config
    class << self
      def load(file)
        @instance = new(file)
      end

      def data
        raise 'config not loaded?' unless @instance.data
        @instance.data
      end
    end

    attr_reader :data

    def initialize(file)
      @file = file
      raise "config file does not exist: #{file}" unless File.exist?(file)
      @data = OpenStruct.new(YAML.load_file(file))
    end

    DEFAULT = <<-EOF
---
region: us-east-1               # AWS Region
key: AWS_ACCESS_KEY_ID          # AWS access key id
secret: AWS_SECRET_ACCESS_KEY   # AWS secret access key
multi: csshX                    # command to use when connecting to multiple servers
single: ssh                     # command to use when connecting to single server
#user: username                 # set user for connection to all servers
                                # this can be overridden on the command line
domain: example.com             # if 'use_names' is set, this will be appended
                                # to names, leave blank if name is fully-qualified
use_names: false                # if true, rather than connecting to IP's,
                                # connection strings will be created using Name
                                # tag and domain
cache: ~/.awssh.cache           # the cache file, set to false to disable caching
expires: 86400                  # cache expiration time in seconds
    EOF
  end
end
