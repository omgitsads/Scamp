require 'celluloid'
require "logger"

require "scamp/version"
require 'scamp/matcher'

class Scamp
  include Celluloid

  attr_accessor :adapters, :plugins, :matchers, :logger, :verbose, :first_match_only

  def initialize(options = {}, &block)
    options ||= {}
    options.each do |k,v|
      s = "#{k}="
      if respond_to?(s)
        send(s, v)
      else
        logger.warn "Scamp initialized with #{k.inspect} => #{v.inspect} but NO UNDERSTAND!"
      end
    end
    
    @matchers ||= []
    @adapters ||= []
    @plugins  ||= []

    yield self if block_given?
  end

  def adapter name, klass, opts={}
    # Supervise the adapter, boot a new one if it crashes.
    klass.supervise_as name, name, self, opts
    @adapters << name
  end

  def plugin klass, opts={}
    plugins << klass.new(self, opts)
  end

  def connect
    # Connect all adapters
    @adapters.each do |name|
      logger.info "Connecting to #{name} adapter"
      Actor[name].connect!
    end

    # Continuely loop poping items off the queues
    loop do
      unless queue.empty?
        logger.info "Got a message"
        adapter, context, msg = queue.pop
        process_message!(adapter, context, msg)
      end
      sleep(0.5)
    end
  end
  
  def queue
    @queue ||= Queue.new
  end

  def command_list
    matchers.map{|m| [m.trigger, m.conditions] }
  end

  def logger
    unless @logger
      # @logger = Logger.new(STDOUT)
      # @logger.level = (verbose ? Logger::DEBUG : Logger::INFO)
      @logger = Celluloid.logger
    end
    @logger
  end

  def verbose
    @verbose = false if @verbose == nil
    @verbose
  end

  def first_match_only
    @first_match_only = false if @first_match_only == nil
    @first_match_only
  end

  def match trigger, params={}, &block
    matchers << Matcher.new(self, {:trigger => trigger, :action => block, :on => params[:on], :conditions => params[:conditions]})
  end
  
  def process_message(adapter, context, msg)
    logger.info "Processing message #{msg} on #{adapter.channel}"
    matchers.each do |matcher|
      matcher.attempt!(adapter.channel, context, msg)
    end
  end
end
