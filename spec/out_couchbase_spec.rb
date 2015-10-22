# vim: fileencoding=utf-8 ts=2 sts=2 sw=2 et si ai :
require 'spec_helper'
require 'couchbase'
Fluent::Test.setup

SPEC_HOSTNAME = 'localhost'
SPEC_NODE_LIST = ['localhost']
SPEC_PORT = 8091
SPEC_POOL_NAME = 'default'
SPEC_BUCKET_NAME = 'default'
SPEC_SECURE_BUCKET_NAME = 'secure'
SPEC_SECURE_BUCKET_PASSWORD = 'secret'
SPEC_TTL = 10
SPEC_INCLUDE_TTL_IN_DOCUMENT = true

CONFIG = %[
  hostname #{SPEC_HOSTNAME}
  port #{SPEC_PORT}
  pool #{SPEC_POOL_NAME}
  bucket #{SPEC_BUCKET_NAME}
  ttl #{SPEC_TTL}
  include_ttl #{SPEC_INCLUDE_TTL_IN_DOCUMENT}
]

CONFIG_NODE_LIST = %[
  node_list #{SPEC_NODE_LIST}
  port #{SPEC_PORT}
  pool #{SPEC_POOL_NAME}
  bucket #{SPEC_BUCKET_NAME}
  ttl #{SPEC_TTL}
  include_ttl #{SPEC_INCLUDE_TTL_IN_DOCUMENT}
]

CONFIG_WITH_PASSWORD = %[
  hostname #{SPEC_HOSTNAME}
  port #{SPEC_PORT}
  pool #{SPEC_POOL_NAME}
  bucket #{SPEC_SECURE_BUCKET_NAME}
  password #{SPEC_SECURE_BUCKET_PASSWORD}
  ttl #{SPEC_TTL}
  include_ttl #{SPEC_INCLUDE_TTL_IN_DOCUMENT}
]

CONFIG_NODE_LIST_WITH_PASSWORD = %[
  node_list #{SPEC_NODE_LIST}
  port #{SPEC_PORT}
  pool #{SPEC_POOL_NAME}
  bucket #{SPEC_SECURE_BUCKET_NAME}
  password #{SPEC_SECURE_BUCKET_PASSWORD}
  ttl #{SPEC_TTL}
  include_ttl #{SPEC_INCLUDE_TTL_IN_DOCUMENT}
]

describe Fluent::CouchbaseOutput do
  include Helpers

  let(:driver) { Fluent::Test::BufferedOutputTestDriver.new(Fluent::CouchbaseOutput, 'test') }

  def set_config_value(config, config_name, value)
    search_text = config.split("\n").map {|text| text if text.strip!.to_s.start_with? config_name.to_s}.compact![0]
    config.gsub(search_text, "#{config_name} #{value}")
  end

  context 'configuring' do

    it 'should be properly configured with hostname' do
      driver.configure(CONFIG)
      driver.instance.hostname.should eq(SPEC_HOSTNAME)
      driver.instance.node_list.should eq(nil)
      driver.instance.port.should eq(SPEC_PORT)
      driver.instance.pool.should eq(SPEC_POOL_NAME)
      driver.instance.bucket.should eq(SPEC_BUCKET_NAME)
      driver.instance.ttl.should eq(SPEC_TTL)
      driver.instance.include_ttl.should eq(SPEC_INCLUDE_TTL_IN_DOCUMENT)
    end

    it 'should be properly configured with hostname and password' do
      driver.configure(CONFIG_WITH_PASSWORD)
      driver.instance.hostname.should eq(SPEC_HOSTNAME)
      driver.instance.node_list.should eq(nil)
      driver.instance.port.should eq(SPEC_PORT)
      driver.instance.pool.should eq(SPEC_POOL_NAME)
      driver.instance.bucket.should eq(SPEC_SECURE_BUCKET_NAME)
      driver.instance.password.should eq(SPEC_SECURE_BUCKET_PASSWORD)
      driver.instance.ttl.should eq(SPEC_TTL)
      driver.instance.include_ttl.should eq(SPEC_INCLUDE_TTL_IN_DOCUMENT)
    end

    it 'should be properly configured with node_list' do
      driver.configure(CONFIG_NODE_LIST)
      driver.instance.hostname.should eq(nil)
      driver.instance.node_list.should eq(SPEC_NODE_LIST)
      driver.instance.port.should eq(SPEC_PORT)
      driver.instance.pool.should eq(SPEC_POOL_NAME)
      driver.instance.bucket.should eq(SPEC_BUCKET_NAME)
      driver.instance.ttl.should eq(SPEC_TTL)
      driver.instance.include_ttl.should eq(SPEC_INCLUDE_TTL_IN_DOCUMENT)
    end

    it 'should be properly configured with node_list and password' do
      driver.configure(CONFIG_NODE_LIST_WITH_PASSWORD)
      driver.instance.hostname.should eq(nil)
      driver.instance.node_list.should eq(SPEC_NODE_LIST)
      driver.instance.port.should eq(SPEC_PORT)
      driver.instance.pool.should eq(SPEC_POOL_NAME)
      driver.instance.bucket.should eq(SPEC_SECURE_BUCKET_NAME)
      driver.instance.password.should eq(SPEC_SECURE_BUCKET_PASSWORD)
      driver.instance.ttl.should eq(SPEC_TTL)
      driver.instance.include_ttl.should eq(SPEC_INCLUDE_TTL_IN_DOCUMENT)
    end

    describe 'exceptions' do
      it 'should raise an exception if hostname is not configured' do
        expect { driver.configure(CONFIG.gsub("hostname", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end

      it 'should raise an exception if node_list is not configured' do
        expect { driver.configure(CONFIG_NODE_LIST.gsub("node_list", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end

      it 'should raise an exception if port is not configured' do
        expect { driver.configure(CONFIG.gsub("port", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end

      it 'should raise an exception if pool is not configured' do
        expect { driver.configure(CONFIG.gsub("pool", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end

      it 'should raise an exception if bucket is not configured' do
        expect { driver.configure(CONFIG.gsub("bucket", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end
    end

  end # context configuring

  context 'logging' do

    it 'should start' do
      driver.configure(CONFIG)
      driver.instance.start
    end

    it 'should shutdown' do
      driver.configure(CONFIG)
      driver.instance.start
      driver.instance.shutdown
    end

    it 'should format' do
      driver.configure(CONFIG)
      time = Time.mktime(2013, 5, 1, 1, 2, 3)
      record = {:a => 1}
      record_expected = record.clone
      record_expected[:tag] = 'test'
      record_expected[:time] = time.to_i

      allow(Time).to receive(:now).and_return(time)
      driver.emit(record)
      driver.expect_format(record_expected.to_msgpack)
      driver.run
    end

    context 'writing' do

      it 'should write' do
        driver.configure(CONFIG)
        write(driver)
      end

    end # context writing

    context 'writing with password' do

      it 'should write' do
        driver.configure(CONFIG_WITH_PASSWORD)
        write(driver)
      end

    end # context writing with password
  end # context logging
end # CouchbaseOutput
