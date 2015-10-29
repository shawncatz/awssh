require 'pp'
module Awssh
  class Command
    def initialize(argv)
      @options = {
          verbose: false,
          config: '~/.awssh',
          multi: false,
          test: false,
          list: false,
          identity: nil,
      }

      @config_file = File.expand_path(@options[:config])
      Awssh::Config.load(@config_file)
      @config = Awssh::Config.data

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
        opts.on('-c', "--config", "override config file (default: ~/.awssh)") do |c|
          @options[:config] = c
        end
        opts.on('-V', '--version', 'print version') do |v|
          puts "awssh version: #{Awssh::Version::STRING}"
          exit 0
        end
        opts.on('-iIDENTITY', '--identity=IDENTITY', 'set ssh key') do |i|
          @options[:identity] = i
        end
        opts.on('--init', 'initialize config') do |i|
          path = File.expand_path(@options[:config])
          puts "creating config file: #{path}"
          if File.exists?(path)
            backup = "#{path}.#{Time.now.to_i}"
            puts "moving previous config to #{backup}"
            FileUtils.mv(path, backup)
          end
          File.open(path, "w+") { |f| f.write Awssh::Config::DEFAULT }
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
        end
        opts.on('--no-cache', 'disable cache for this run') do |u|
          @config.cache = false
        end
        opts.separator ''
        opts.on('-m', '--[no-]multi', 'connect to multiple servers') do |m|
          @options[:multi] = m
        end
        opts.on('-u', '--user USER', 'override user setting') do |u|
          @config.user = u
        end
      end.parse!(argv)

      @cloud = Awssh::Cloud.connect(@config.key, @config.secret, @config.region)
      @cache = Awssh::Cache.create(@config.cache_type, @config)
      @search = argv

      if @options[:update]
        cache(:servers, true) { @cloud.servers }
        exit 0
      end

      if @options[:verbose]
        puts "options: #{@options.inspect}"
        puts "config: #{@config.inspect}"
      end
    end

    def run
      @servers = cache(:servers) { @cloud.servers }
      search = Awssh::Search.new(@servers, @search)
      list = search.filter
      hosts = hosts(list)

      if hosts.count == 0
        puts "no servers found."
        exit 1
      end

      multi_not_multi = (hosts.count > 1 && !@options[:multi])

      if @options[:list] || @options[:verbose] || multi_not_multi
        puts_hosts(hosts)
      end
      puts "#{hosts.count} servers found" if @options[:verbose]
      exit 0 if @options[:list]
      if multi_not_multi
        puts "more than one server found and multi is false"
        puts "use the -m flag to connect to multiple servers"
        exit 1
      end

      connect(hosts)
    end

    def connect(hosts)
      cmd = command(hosts)
      if @options[:test] || @options[:verbose]
        puts cmd
      end
      exec(cmd) unless @options[:test]
    end

    def command(hosts)
      id = @options[:identity] ? "-i #{@options[:identity]}" : nil
      if @options[:multi]
        command = "#{@config.multi} #{id} #{hosts.map { |e| host(e) }.join(' ')}"
      else
        command = "#{@config.single} #{id} #{host(hosts.first)}"
      end
      command
    end

    def cache(key, force=!@config.cache, &block)
      @cache.fetch(key, force, &block)
    end

    def hosts(list)
      list.map do |l|
        (id,_) = l.split('||')
        @servers.to_a.detect {|e| e[:id] == id}
      end.compact.sort_by {|e| e[:name]}
    end

    def host(host)
      out = []
      out << "#{@config.user}@" if @config.user
      if @config.use_names
        out << [host[:name], @config.domain].compact.join('.')
      else
        out << host[:private]
      end
      out.join('')
    end

    def puts_hosts(hosts)
      hosts.each do |host|
        puts "%10s   %-15s   %s" % [host[:id], host[:private], host[:name]]
      end
    end
  end
end
