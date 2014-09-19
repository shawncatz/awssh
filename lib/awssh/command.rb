module Awssh
  class Command
    def initialize(argv)
      @options = {
          verbose: false,
          config: '~/.awssh',
          multi: false,
          test: false,
          list: false,
      }
      @config = {
          multi: 'csshX',
          single: 'ssh',
          region: 'us-east-1',
          user: nil,
          key: 'AWS ACCESS KEY ID',
          secret: 'AWS SECRET ACCESS KEY',
          domain: 'example.com',
          cache: '~/.awssh.cache',
          expires: 1.day
      }.stringify_keys

      @config_file = File.expand_path(@options[:config])
      @config.merge!(YAML.load_file(@config_file)||{}) if File.exists?(@config_file)

      OptionParser.new do |opts|
        opts.banner = "Usage: awssh [options] [search terms]"

        opts.separator ''
        opts.separator 'Search Terms:'
        opts.separator '  matches against AWS Tag "Name"'
        opts.separator '  positive check for each entry'
        opts.separator '    name =~ /term/'
        opts.separator '  negative check if the term starts with ^'
        opts.separator '    name !~ /term/'
        opts.separator ''
        opts.separator 'Options:'
        opts.on('-V', '--version', 'print version') do |v|
          puts "awssh version: #{Awssh::Version::STRING}"
          exit 0
        end
        opts.on('-i', '--init', 'initialize config') do |i|
          path = File.expand_path("~/.awssh")
          File.open(path, "w+") { |f| f.write @config.to_yaml }
          puts "created config file: #{path}"
          exit 0
        end
        opts.separator ''
        opts.on('-l', '--list', 'just list servers') do |l|
          @options[:list] = true
        end
        opts.on('-n', '--test', 'just output ssh command') do |n|
          @options[:test] = n
        end
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          @options[:verbose] = v
        end

        opts.separator ''
        opts.on('-U', '--update', 'just update the cache') do |u|
          @options[:update] = true
          get_servers
          exit 0
        end
        opts.on('--no-cache', 'disable cache for this run') do |u|
          @config['cache'] = false
        end
        opts.separator ''
        opts.on('-m', '--[no-]multi', 'connect to multiple servers') do |m|
          @options[:multi] = m
        end
        opts.on('-c', "--config", "override config file (default: ~/.awssh)") do |c|
          @options[:config] = c
        end
        opts.on('-u', '--user USER', 'override user setting') do |u|
          @config['user'] = u
        end
      end.parse!(argv)

      @search = argv

      if @options[:verbose]
        p @search
        p @options
        p @config
      end
    end

    def connect
      @servers = find_servers

      if @options[:verbose] || @options[:list]
        print_list
      end
      return if @options[:list]

      if @servers.count > 1 && !@options[:multi]
        print_list
        puts "more than one server found, and multi is false"
        puts "set the -m flag to connect to more than one matched server"
        exit 1
      end

      if @servers.count == 0
        puts "no servers found"
        exit 1
      end

      @command = get_command(@servers)

      puts "running: #{@command}"
      exec @command unless @options[:test]
    end

    private

    def print_list
      puts "found: #{@servers.count}"
      @servers.each do |s|
        puts "- #{s}"
      end
    end

    def find_servers
      servers = []
      get_servers.each do |n|
        fail = false
        @search.each do |v|
          if v =~ /^\^/
            fail = true if n =~ /#{v.gsub(/^\^/, '')}/
          else
            fail = true unless n =~ /#{v}/
          end
        end
        next if fail
        servers << n
      end
      servers
    end

    def get_servers
      list = get_cache do
        server_names
      end
      puts "total servers: #{list.count}" if @options[:verbose]
      list.sort
    end

    def get_cache
      if @config['cache']
        file = File.expand_path(@config['cache'])
        if File.exists?(file)
          unless @options[:update]
            if Time.now - File.mtime(file) < @config['expires']
              return YAML.load_file(file)
            end
          end
        end
        puts "updating cache ..."
        list = yield
        File.open(file, "w+") { |f| f.write list.to_yaml }
        return list
      end
      list = yield
      return list
    end

    def server_names
      puts "requesting servers ..."
      @fog = Fog::Compute.new(provider: 'AWS', aws_access_key_id: @config['key'], aws_secret_access_key: @config['secret'], region: @config["region"])
      list = @fog.servers.all
      list.inject([]) { |a, e| a << e.tags['Name'] }
    end

    def get_command(servers)
      if @options[:multi]
        command = "#{@config["multi"]} #{servers.map { |e| server_url(e) }.join(' ')}"
      else
        command = "#{@config["single"]} #{server_url(servers.first)}"
      end
      command
    end

    def server_url(server)
      out = []
      out << "#{@config["user"]}@" if @config["user"]
      out << server
      out << ".#{@config["domain"]}" if @config["domain"]
      out.join('')
    end
  end
end
