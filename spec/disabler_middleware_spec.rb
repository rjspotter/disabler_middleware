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

  context "base setup" do
    
    before do
      @disabler = Rack::Disabler.new(app,store,{})
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
        @disabled = Rack::Disabler.new(app,store,
                                       {
                                         'freeloader' =>  [402, {}, ['Payment Required']]
                                       }
                                       ) {|env| "disableddeveloperkey"}
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
        @allowed = Rack::Disabler.new(app,store,{}) {|env| "alloweddeveloperkey"}
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
