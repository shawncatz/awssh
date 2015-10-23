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
    end

    def servers
      puts "requesting servers..."
      Aws.config.update({region: @region, credentials: Aws::Credentials.new(@key, @secret)})
      aws = Aws::EC2::Resource.new
      aws.instances(filters:[{name: 'instance-state-name', values: ['running']}]).inject([]) do |a, instance|
        tags = tags(instance)
        a << {
            id: instance.id,
            name: tags['name'] || instance.id,
            tags: tags,
            private: instance.private_ip_address,
            public: instance.public_ip_address,
        }
      end
    end

    private

    def tags(instance)
      instance.tags.inject({}) {|h, e| h[e.key.downcase]=e.value.downcase; h}
    end
  end
end
