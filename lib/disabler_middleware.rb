
module Rack

  class Disabler
    
    def initialize(app, options = {}, &block)
      @app, @store, @responses = app, options[:store], (options[:responses] || {})
      @extractor = block || lambda {|env| }
    end

    def call(env)
      @responses[@store.get(@extractor.call(env))] || @app.call(env)
    end

  end

end
