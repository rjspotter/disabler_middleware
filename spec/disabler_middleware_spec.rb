require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def make_env(path = '/foo/uid/bar', props = {})
  {
    'REQUEST_METHOD' => 'GET',
    'PATH_INFO' => path,
    'rack.session' => {},
    'rack.input' => ::StringIO.new('test=true')
  }.merge(props)
end

describe "DisablerMiddleware" do
  
  let(:app){ lambda{|env| [404, {}, ['Awesome']]}}

  let(:store) do
    store = double()
    store.stub(:get)
  end

  context "accessors" do
    
    before do
      @disabler = Rack::Disabler.new(app) do |dis|
        dis.store = store
      end
    end

    it "should have the store be settable" do
      expect {@disabler.store = "somthing else"}.should_not raise_error
    end

    it "should retrieve set store" do
      @disabler.store = foo = "something"
      @disabler.store.should == foo
    end

    it "should allow setting of additional responses" do
      expect {@disabler.responses = {'foo' => 'bar'}}.should_not raise_error
    end

    it "should make those additional responses available" do
      @disabler.responses = {'foo' => 'bar'}
      @disabler.response('foo').should == 'bar'
    end

    it "should allow the adding of single responses" do
      @disabler.should respond_to(:add_response)
    end

    it "should add that single response to the collection" do
      @disabler.add_response('baz','cool')
      @disabler.response('baz').should == 'cool'
    end

    context "defautl responses" do
      it "should provide a default responses for non-payment" do
        @disabler.response('freeloader').should == [402, {}, ["Payment Required"]]
      end

      it "should provide a default responses for abuse" do
        @disabler.response('douchebag').should == [403, {}, ["Forbidden"]]
      end
    end

    it "should be able to bulk add respeonses" do
      @disabler.add_responses({'white' => 'rabbit', 'red' => 'pill'})
      %w[white red freeloader].inject(true) {|m,x| !! m && x}.should be_true
    end

    context "overwriting responses" do
      
      it "should work with single" do
        @disabler.add_response('douchebag',[418,{},"Tip me over and pour me out"])
        @disabler.response('douchebag').should == [418,{},"Tip me over and pour me out"]
      end

      it "should work with many" do
        @disabler.add_responses({'douchebag' => [418,{},"Tip me over and pour me out"]})
        @disabler.response('douchebag').should == [418,{},"Tip me over and pour me out"]
      end

    end

    context "extractor" do
      
      it "should allow setting of the extractor with a block" do
        expect {@disabler.extractor {|req| "foo"} }.should_not raise_error
      end

      it "should make the callable extractor availabe" do
        @disabler.extractor {|foo| 'bar'}
        @disabler.extract("something").should == "bar"
      end

    end

  end

  context "base setup" do
    
    before do
      @disabler = Rack::Disabler.new(app) do |dis|
        dis.store = store 
        dis.responses = {}
        dis.extractor {|env| "foo"}
      end
    end
    
    it "should take an app and store it for later" do
      @disabler.instance_variables.should include(:@app)
    end
    
    it "should take a store and store it for later" do
      @disabler.instance_variables.should include(:@store)
    end

    it "should take a response hash for later" do
      @disabler.instance_variables.should include(:@responses)
    end

    it "should take block to extract the uid" do
      @disabler.instance_variables.should include(:@extractor)
    end

    it "should have exctractor be callable" do
      @disabler.instance_eval('@extractor').should respond_to(:call)
    end

  end

  context "call functionality" do

    context "disabled developer" do

      before do
        @disabled = Rack::Disabler.new(app) do |dis|
          dis.store = store
          dis.extractor {|env| "disableddeveloperkey"}
        end
      end

      it "should call store with disableddeveloperkey" do
        store.should_receive(:get).with("disableddeveloperkey")
        @disabled.call(make_env('/disableddeveloperkey'))
      end

      it "should return freeloader response" do
        store.should_receive(:get).with("disableddeveloperkey").and_return("freeloader")
        @disabled.call(make_env('/disableddeveloperkey')).should == [402, {}, ['Payment Required']]
      end

    end

    context "allowed developer" do
      before do
        @allowed = Rack::Disabler.new(app) do |dis|
          dis.store = store
          dis.extractor {|env| "alloweddeveloperkey"}
        end
      end

      it "should lookup developer" do
        store.should_receive(:get).with("alloweddeveloperkey")
        @allowed.call(make_env('/alloweddeveloperkey'))
      end

      it "should call the app because the developer is allowed" do
        store.should_receive(:get).with("alloweddeveloperkey").and_return(nil)
        app.should_receive(:call)
        @allowed.call(make_env('/alloweddeveloperkey'))
      end
    end
    
  end

end
