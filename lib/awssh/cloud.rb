module Awssh
  class Cloud
    class << self
      def connect(key, secret, region)
        @instance = new(key, secret, region)
      end
      def instance
        raise "not connected?" unless @instance
        @instance
      end
    end

    def initialize(key, secret, region)
      @key = key
      @secret = secret
      @region = region
      @fog = Fog::Compute.new(provider: 'AWS', aws_access_key_id: @key, aws_secret_access_key: @secret, region: @region)
    end

    def servers
      puts "requesting servers..."
      list = @fog.servers.all({'instance-state-name' => 'running'})
      list.inject([]) do |a, e|
        a << {
          id: e.id,
          name: e.tags['Name'],
          tags: e.tags.inject({}) {|h, e| (k,v) = e; h[k.downcase] = v.downcase; h},
          private: e.private_ip_address,
          public: e.public_ip_address,
        }
      end
    end
  end
end