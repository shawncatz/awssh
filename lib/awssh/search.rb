module Awssh
  class Search
    def initialize(servers, terms)
      @db = db(servers)
      @terms = convert(terms)
    end

    def filter
      list = @db
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

    def convert(terms)
      terms.inject([]) do |a, e|
        opts = {}
        term = e.downcase
        if term =~ /\:/
          (key, value) = term.split(':')
        else
          key = 'name'
          value = term
          if term =~ /^\^/
            value = term.gsub(/^\^/, '')
            key = "^#{k}"
          end
        end
        if key =~ /^\^/
          opts[:inverse] = true
          key.gsub!(/^\^/)
        end
        a << [key, value, opts]
      end
    end

    def db(servers)
      servers.inject([]) { |a, s| a << "#{s[:id]}|| #{s[:tags].inject([]) { |a, e| a << e.join(':') }.join(' ')}" }
    end
  end
end
