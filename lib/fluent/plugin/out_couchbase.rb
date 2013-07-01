# vim: fileencoding=utf-8 ts=2 sts=2 sw=2 et si ai :
require 'couchbase'
require 'msgpack'
require 'json'
require 'active_support/core_ext/hash'
require 'digest/md5'

module Fluent

  class CouchbaseOutput < BufferedOutput
    Fluent::Plugin.register_output('couchbase', self)

    config_param :hostname,      :string
    config_param :port,          :integer
    config_param :pool,          :string
    config_param :bucket,        :string
    config_param :password,      :string, :default => nil
    config_param :ttl,           :integer, :default => 0
    config_param :include_ttl,   :bool, :default => false

    def connection
      @connection ||= get_connection(self.hostname, self.port, self.pool, self.bucket, self.password)
    end

    def configure(conf)
      super

      # perform validations
      raise ConfigError, "'hostname' is required by Couchbase output (ex: localhost)" unless self.hostname
      raise ConfigError, "'port' is required by Couchbase output (ex: 8091)" unless self.port
      raise ConfigError, "'pool' is required by Couchbase output (ex: default)" unless self.pool
      raise ConfigError, "'bucket' is required by Couchbase output (ex: default)" unless self.bucket
      raise ConfigError, "'ttl' is required by Couchbase output (ex: 0)" unless self.ttl
    end

    def start
      super
      connection
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      record['tag'] = tag
      record['time'] = time
      record.to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each  { |record|
        # store ttl in the document itself?
        record[:ttl] = self.ttl if self.include_ttl

        # persist
        connection[generate_id(record), :ttl => self.ttl] = record
      }
    end

    private

    def generate_id(record)
      Digest::MD5.hexdigest(record.to_s)
    end

    def get_connection(hostname, port, pool, bucket, password = nil)
      if password.nil?
        Couchbase.connect(:hostname => hostname,
                          :port => port,
                          :pool => pool,
                          :bucket => bucket)
      else
        Couchbase.connect(:hostname => hostname,
                          :port => port,
                          :pool => pool,
                          :bucket => bucket,
                          :password => password)
      end
    end

  end
end
