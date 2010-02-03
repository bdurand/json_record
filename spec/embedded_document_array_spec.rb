require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe JsonRecord::EmbeddedDocumentArray do
  it "should be an Array" do
    a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, nil)
    a.is_a?(Array).should == true
  end
  
  it "should convert hashes to objects on initialize and set the parent" do
    parent = JsonRecord::Test::Trait.new(:name => "name")
    obj = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    hash = {:name => "n2", :value => "v2"}
    a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, parent, [obj, hash])
    obj.parent.should == parent
    a.collect{|t| [t.name, t.value, t.parent]}.should == [["n1", "v1", parent], ["n2", "v2", parent]]
  end
  
  it "should convert hashes to objects on concat and set the parent" do
    parent = JsonRecord::Test::Trait.new(:name => "name")
    obj = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    hash = {:name => "n2", :value => "v2"}
    a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, parent)
    a.concat([obj, hash])
    obj.parent.should == parent
    a.collect{|t| [t.name, t.value, t.parent]}.should == [["n1", "v1", parent], ["n2", "v2", parent]]
  end
  
  it "should convert hashes to objects on append and set the parent" do
    parent = JsonRecord::Test::Trait.new(:name => "name")
    obj = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    hash = {:name => "n2", :value => "v2"}
    a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, parent)
    a << obj
    a << hash
    obj.parent.should == parent
    a.collect{|t| [t.name, t.value, t.parent]}.should == [["n1", "v1", parent], ["n2", "v2", parent]]
  end
  
  it "should have a build method that appends the values and set the parent" do
    parent = JsonRecord::Test::Trait.new(:name => "name")
    obj = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    hash = {:name => "n2", :value => "v2"}
    a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, parent)
    a.build(obj).should == obj
    obj.parent.should == parent
    obj_2 = a.build(hash)
    obj_2.name.should == "n2"
    obj_2.value.should == "v2"
    obj_2.parent.should == parent
    a.collect{|t| [t.name, t.value, t.parent]}.should == [["n1", "v1", parent], ["n2", "v2", parent]]
  end
  
  it "should not accept objects that are not the correct class" do
    parent = JsonRecord::Test::Trait.new(:name => "name")
    obj = JsonRecord::Test::Trait.new(:name => "n1", :value => "v1")
    hash = {:name => "n2", :value => "v2"}
    lambda{a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, parent, "bad object")}.should raise_error(ArgumentError)
    a = JsonRecord::EmbeddedDocumentArray.new(JsonRecord::Test::Trait, parent)
    lambda{a.concat(["bad object"])}.should raise_error(ArgumentError)
    lambda{a << "bad object"}.should raise_error(ArgumentError)
    lambda{a.build("bad object")}.should raise_error(ArgumentError)
  end
  
end
