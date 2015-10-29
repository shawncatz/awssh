require 'sqlite3'

module Awssh
  module Cache
    class Sqlite < Base
      attr_reader :data

      def initialize(config)
        @config = config
        @disabled = false
        @expires = @config.expires
        @file = File.expand_path("#{@config.cache}.sql")
        _connect
      end

      def write(key, value)
        FileUtils.rm_rf(@file)
        _connect
        value.each do |data|
          @db.execute "insert into #{key} values (?, ?, ?, ?)",
                      data[:id],
                      data[:name],
                      data[:public],
                      data[:private]
        end
        @db.execute "insert into timestamps values ('servers', strftime('%s','now'))"
        @timestamps = nil
      end

      def read(key)
      end

      def fetch(key, force)
        if force || @disabled
          diff = Time.now.to_i
        else
          time = timestamps[key] || 0
          diff = Time.now.to_i - time
        end
        puts "diff: #{key} #{diff} #{timestamps[key]}"
        if diff > @expires
          value = yield
          write(key, value)
          return value
        else
          read(key)
        end
      end

      def filter(terms)
        term = term.first
        out = []
        @db.execute("select * from servers where id = ?", term) do |row|
          puts row.inspect
          out << row
        end
        out
      end

      protected

      def load

      end

      def save
        # return if @disabled
        # File.open(@file, "w+") { |f| f.write(@data.to_yaml) }
      end

      private

      def _connect
        exists = File.exists?(@file)
        @db = SQLite3::Database.new @file
        unless exists
          @db.execute <<-SQL
            create table timestamps (
              id varchar(12),
              expires int
            );
          SQL
          @db.execute <<-SQL
            create table servers (
              id varchar(10),
              name varchar(255),
              private varchar(32),
              public varchar(32)
            );
          SQL
        end
        @db
      end

      def timestamps
        @timestamps ||= begin
          out = {}
          @db.execute("select * from timestamps") do |row|
            puts row.inspect
            out[row[0]] = row[1]
          end
          out
        end
      end
    end
  end
end
