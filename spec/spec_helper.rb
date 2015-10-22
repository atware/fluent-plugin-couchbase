# vim: fileencoding=utf-8 ts=2 sts=2 sw=2 et si ai :
#$require 'simplecov'
require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
Bundler.require(:default, :test)

require 'simplecov'
require 'rspec'
require 'mocha'
require 'fluent/test'
require 'digest/md5'

# require the library files
Dir["./lib/**/*.rb"].each {|f| require f}

# require the shared example files
Dir["./spec/support/**/*.rb"].each {|f| require f}
