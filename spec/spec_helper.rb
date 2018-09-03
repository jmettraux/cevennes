
#
# Specifying cevennes
#
# Mon Sep  3 11:56:05 JST 2018
#

require 'pp'
require 'yaml'

require 'cevennes'

#def jruby?
#
#  !! RUBY_PLATFORM.match(/java/)
#end

def paml(x)

  puts(YAML.dump(x))
end

