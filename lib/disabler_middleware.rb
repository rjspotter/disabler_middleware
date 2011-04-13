
module Rack

  class Disabler
    
    def initialize(app, store, responses, &block)
      @app, @store, @responses = app, store, responses
      @extractor = block || lambda {|env| }
    end

    def call(env)
      @responses[@store.get(@extractor.call(env))] || @app.call(env)
    end

  end

end
