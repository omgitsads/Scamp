class Scamp
  class Adapter
    include Celluloid
    attr_reader :channel

    def initialize(channel, bot, opts={})
      @channel = channel
      @bot = bot
      @opts = opts
      @block = nil
    end

    def push(msg)
      @bot.queue.push [self, *msg]
    end
    alias_method :<<, :push

    def connect
      raise NotImplementedError, "#connect must be implemented"
    end
  end
end
