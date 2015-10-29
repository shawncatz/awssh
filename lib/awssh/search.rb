module Awssh
  class Search
    def initialize(cache, terms)
      @cache = cache
      @terms = convert(terms)
    end

    def filter
      @cache.filter(@terms)
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
  end
end
