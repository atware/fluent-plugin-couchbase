# vim: fileencoding=utf-8 ts=2 sts=2 sw=2 et si ai :
require 'couchbase'
require 'msgpack'
require 'json'
require 'active_support/core_ext/hash'
require 'digest/md5'

module Fluent

  class CouchbaseOutput < BufferedOutput
    Fluent::Plugin.register_output('couchbase', self)

    config_param :hostname,      :string, :default => nil
    config_param :node_list,     :array, :default => nil
    config_param :port,          :integer
    config_param :pool,          :string
    config_param :bucket,        :string
    config_param :password,      :string, :default => nil
    config_param :ttl,           :integer, :default => 0
    config_param :include_ttl,   :bool, :default => false

    def connection
      @connection ||= get_connection
    end

    def configure(conf)
      super

      # perform validations
      raise ConfigError, "either 'hostname' or 'node_list' is required by Couchbase output (ex: localhost)" unless self.hostname or self.node_list
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
        if record.has_key?('key')
          connection[record.delete('key'), :ttl => self.ttl] = record
        else
          connection[generate_id(record), :ttl => self.ttl] = record
        end
      }
    end

    private

    def generate_id(record)
      Digest::MD5.hexdigest(record.to_s)
    end

    def get_connection
      if self.hostname
        if password.nil?
          Couchbase.connect(:hostname => self.hostname, :port => self.port, :pool => self.pool, :bucket => self.bucket)
        else
          Couchbase.connect(:hostname => self.hostname, :port => self.port, :pool => self.pool, :bucket => self.bucket, :password => self.password)
        end
      elsif self.node_list
        if password.nil?
          Couchbase.connect(:node_list => self.node_list, :port => self.port, :pool => self.pool, :bucket => self.bucket)
        else
          Couchbase.connect(:node_list => self.node_list, :port => self.port, :pool => self.pool, :bucket => self.bucket, :password => self.password)
        end
      end
    end

  end
end
