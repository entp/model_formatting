$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'action_controller'
require 'action_view'
require 'active_support/core_ext'
require 'model_formatting'
require 'model_formatting/init'
require 'model_formatting/config'
require 'model_formatting/instance_methods'
require 'context'
require 'matchy'

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end