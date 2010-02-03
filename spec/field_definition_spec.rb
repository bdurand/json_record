require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe JsonRecord::FieldDefinition do
  
  it "should have a name that is a string" do
    field = JsonRecord::FieldDefinition.new("name", :type => Integer)
    field.name.should == "name"
  end
  
  it "should have a type" do
    field = JsonRecord::FieldDefinition.new("name", :type => Integer)
    field.type.should == Integer
  end
  
  it "should have a default" do
    field = JsonRecord::FieldDefinition.new("name", :type => Integer)
    field.default.should == nil
    field = JsonRecord::FieldDefinition.new("name", :type => Integer, :default => 10)
    field.default.should == 10
  end
  
  it "can be multivalued" do
    field = JsonRecord::FieldDefinition.new("name", :type => Integer)
    field.multivalued?.should == false
    field = JsonRecord::FieldDefinition.new("name", :type => Integer, :multivalued => true)
    field.multivalued?.should == true
  end
  
end
