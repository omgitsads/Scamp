$:.unshift File.join(File.dirname(__FILE__), '../lib')

require 'scamp'
require 'scamp/adapter'
require 'scamp/message'
require 'scamp/plugin'

class PingPlugin < Scamp::Plugin
  match /^ping/, :say_pong

  def say_pong channel, msg
    puts msg.matches.inspect
    channel.say "pong"
  end
end

class TestAdapter < Scamp::Adapter
  class Context
    def say msg
      puts msg
    end
  end

  def connect
    @timer = after(@opts[:delay]) do
      puts "Saying ping"
      msg = Scamp::Message.new(self, :body => "ping")
      context = TestAdapter::Context.new
      push [context, msg]
      @timer.reset
    end
  end
end

Scamp.new do |bot|
  bot.adapter :test, TestAdapter, :delay => 1
  bot.adapter :another, TestAdapter, :delay => 5

  bot.plugin PingPlugin, :on => [:test]

  bot.connect!
end

sleep
