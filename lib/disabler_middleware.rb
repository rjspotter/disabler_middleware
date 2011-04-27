
module Rack

  class Disabler
    
    def initialize(app,store = nil)
      @responses,@app,@store = {
        'freeloader' =>  [402, {}, ["Payment Required"]],
        'douchebag'  =>  [403, {}, ["Forbidden"]]
      },app,store
      yield self if block_given?
    end

    attr_accessor :store, :responses

    def store
      @store ||= Redis.new
    end

    def add_response(key,val)
      @responses[key.to_s] = val
    end

    def add_responses(hsh)
      @responses.merge!(hsh)
    end

    def response(key)
      @responses[key]
    end

    def extractor(&block)
      @extractor = block
    end

    def extract(env)
      (@extractor || lambda {|env| Rack::Request.new(env).path}).call(env)
    end

    def call(env)
      response(store.get(extract(env))) || @app.call(env)
    end

  end

end
