require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe SlenderT do
    
  it "should initialize with three triple indexes" do
    st = SlenderT.new
    st.spo.should be_is_a(Hash)
    st.pos.should be_is_a(Hash)
    st.osp.should be_is_a(Hash)
  end

  context "add and remove" do
    before do
      @st = SlenderT.new
    end
    
    it "should be able to add a triple" do
      @st.add(:foo, :bar, :baz)
      @st.spo[:foo].should be_is_a(Hash)
      @st.spo[:foo][:bar].should eql([:baz])
      @st.pos[:bar].should be_is_a(Hash)
      @st.pos[:bar][:baz].should eql([:foo])
      @st.osp[:baz].should be_is_a(Hash)
      @st.osp[:baz][:foo].should eql([:bar])
    end
    
    it "should not add a triple more than once, i.e. duplicate entries are not created" do
      @st.add(:foo, :bar, :baz)
      @st.add(:foo, :bar, :baz)
      @st.spo[:foo][:bar].should eql([:baz])
      @st.pos[:bar][:baz].should eql([:foo])
      @st.osp[:baz][:foo].should eql([:bar])
    end
    
    it "should be able to remove a triple" do
      @st.add(:foo, :bar, :baz)
      @st.remove(:foo, :bar, :baz)
      @st.spo.should_not be_include(:foo)
      @st.pos.should_not be_include(:bar)
      @st.osp.should_not be_include(:baz)
    end
    
    it "should not complain when removing a non-existent triple" do
      @st.add(:foo, :bar, :baz)
      @st.remove(:foo, :bar, :baz)
      @st.remove(:foo, :bar, :baz)
      lambda{@st.remove(:foo, :bar, :baz)}.should_not raise_error
    end
    
  end
  
  context "query" do
    before do 
      @st = SlenderT.new
      @st.add(:a, :implies, :b)
      @st.add(:a, :implies, :d)
      @st.add(:c, :implies, :d)
      @st.add(:d, :implies, :e)
      @st.add(:f, :implies, :a)
      @st.add(:e, :implies, :a)
      @st.add(:b, :implies, :c)
      @st.add(:a, :does_not_imply, :c)
    end
    
    it "should be able to find an exact triple, returning an array of arrays" do
      @st.find(:a, :implies, :b).should eql([[:a, :implies, :b]])
      @st.find(:c, :implies, :d).should eql([[:c, :implies, :d]])
    end
    
    it "should return an empty set if an exact triple can't be found" do
      @st.find(:x, :implies, :y).should eql([])
    end
    
    it "should find all matching subjects and predicates" do
      @st.find(:a, :does_not_imply).should eql([[:a, :does_not_imply, :c]])
      @st.find(:a, :implies).should eql([[:a, :implies, :b],[:a, :implies, :d]])
    end
    
    it "should find all matching subjects and objects" do
      @st.find(:a, nil, :d).should eql([[:a, :implies, :d]])
      @st.find(:b, nil, :c).should eql([[:b, :implies, :c]])
    end
    
    it "should find all matching subjects" do
      found = @st.find(:a)
      found.size.should eql(3)
      found.should be_include([:a, :implies, :b])
      found.should be_include([:a, :implies, :d])
      found.should be_include([:a, :does_not_imply, :c])
    end
    
    it "should find all matching predicates and objects" do
      found = @st.find(nil, :implies, :d)
      found.size.should eql(2)
      found.should be_include([:a, :implies, :d])
      found.should be_include([:c, :implies, :d])
      @st.find(nil, :implies, :e).should eql([[:d, :implies, :e]])
    end

    it "should find all matching predicates" do
      found = @st.find(nil, :implies, nil)
      found.size.should eql(7)
      found.should be_include([:a, :implies, :b])
      found.should be_include([:a, :implies, :d])
      found.should be_include([:c, :implies, :d])
      found.should be_include([:d, :implies, :e])
      found.should be_include([:f, :implies, :a])
      found.should be_include([:e, :implies, :a])
      found.should be_include([:b, :implies, :c])
      @st.find(nil, :does_not_imply, nil).should eql([[:a, :does_not_imply, :c]])
    end

    it "should find all matching objects" do
      found = @st.find(nil, nil, :d)
      found.size.should eql(2)
      found.should be_include([:a, :implies, :d])
      found.should be_include([:c, :implies, :d])
      @st.find(nil, nil, :e).should eql([[:d, :implies, :e]])
    end
    
    it "should find all triplets" do
      found = @st.find(nil, nil, nil)
      found.size.should eql(8)
      found.should be_include([:a, :implies, :b])
      found.should be_include([:a, :implies, :d])
      found.should be_include([:c, :implies, :d])
      found.should be_include([:d, :implies, :e])
      found.should be_include([:f, :implies, :a])
      found.should be_include([:e, :implies, :a])
      found.should be_include([:b, :implies, :c])
      found.should be_include([:a, :does_not_imply, :c])
    end
    
    it "should be able to see the missing value of the first queried result" do
      @st.value(:a, :implies).should eql(:b)
    end
  end
  
  context "load" do
    
    it "should be able to load file contents from the class method" do
      @st = SlenderT.load(simple_filename)
      found = @st.find(nil, nil, nil)
      found.size.should eql(8)
      found.should be_include(%w(a implies b))
      found.should be_include(%w(a implies d))
      found.should be_include(%w(c implies d))
      found.should be_include(%w(d implies e))
      found.should be_include(%w(f implies a))
      found.should be_include(%w(e implies a))
      found.should be_include(%w(b implies c))
      found.should be_include(%w(a does_not_imply c))
    end
    
    it "should be able to load csv string from the class method" do
      @st = SlenderT.load(simple_content)
      found = @st.find(nil, nil, nil)
      found.size.should eql(8)
      found.should be_include(%w(a implies b))
      found.should be_include(%w(a implies d))
      found.should be_include(%w(c implies d))
      found.should be_include(%w(d implies e))
      found.should be_include(%w(f implies a))
      found.should be_include(%w(e implies a))
      found.should be_include(%w(b implies c))
      found.should be_include(%w(a does_not_imply c))
    end
    
    it "should be able to load file contents from the instance method" do
      @st = SlenderT.new
      @st.load(simple_filename)
      found = @st.find(nil, nil, nil)
      found.size.should eql(8)
      found.should be_include(%w(a implies b))
      found.should be_include(%w(a implies d))
      found.should be_include(%w(c implies d))
      found.should be_include(%w(d implies e))
      found.should be_include(%w(f implies a))
      found.should be_include(%w(e implies a))
      found.should be_include(%w(b implies c))
      found.should be_include(%w(a does_not_imply c))
    end
    
    it "should be able to load csv string from the instance method" do
      @st = SlenderT.new
      @st.load(simple_content)
      found = @st.find(nil, nil, nil)
      found.size.should eql(8)
      found.should be_include(%w(a implies b))
      found.should be_include(%w(a implies d))
      found.should be_include(%w(c implies d))
      found.should be_include(%w(d implies e))
      found.should be_include(%w(f implies a))
      found.should be_include(%w(e implies a))
      found.should be_include(%w(b implies c))
      found.should be_include(%w(a does_not_imply c))
    end
    
  end
  
end
