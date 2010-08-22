require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe JsonRecord::Serialized do
  before(:all) do
    JsonRecord::Test.create_tables
  end
  
  after(:all) do
    JsonRecord::Test.drop_tables
  end
  
  it "should have accessors for json attributes and not interfere with column attribute accessors" do
    model = JsonRecord::Test::Model.new
    model.name.should == nil
    model.name = "test"
    model.name.should == "test"
    model[:name].should == "test"
    model['name'].should == "test"
    model[:name] = "new value"
    model.name.should == "new value"
    model.string_field = "a"
    model.string_field.should == "a"
    model[:string_field] = "b"
    model[:string_field].should == "b"
  end
  
  it "should convert blank values to nil" do
    model = JsonRecord::Test::Model.new
    model.name = ""
    model.name.should == nil
  end
  
  it "should convert values to strings" do
    model = JsonRecord::Test::Model.new
    model.name = 1
    model.name.should == "1"
  end
  
  it "should convert values to integers" do
    model = JsonRecord::Test::Model.new
    model.value = "1"
    model.value.should == 1
  end
  
  it "should convert values to floats" do
    model = JsonRecord::Test::Model.new
    model.price = "1.2"
    model.price.should == 1.2
  end
  
  it "should convert values to dates" do
    model = JsonRecord::Test::Model.new
    model.when = "2010-01-25"
    model.when.should == Date.civil(2010, 1, 25)
  end
  
  it "should convert values to times" do
    model = JsonRecord::Test::Model.new
    model.verified_at = "2010-01-25T12:00:15-6:00"
    model.verified_at.should == Time.parse("2010-01-25T12:00:15-6:00").utc
  end
  
  it "should convert values to datetimes" do
    model = JsonRecord::Test::Model.new
    model.viewed_at = "2010-01-25T12:00:15-6:00"
    model.viewed_at.should == Time.parse("2010-01-25T12:00:15-6:00").utc
  end
  
  it "should convert values to booleans" do
    model = JsonRecord::Test::Model.new
    model.verified = "true"
    model.verified.should == true
    model.verified = "false"
    model.verified.should == false
    model.verified = "1"
    model.verified?.should == true
    model.verified = "0"
    model.verified?.should == false
    model.verified = 1
    model.verified?.should == true
    model.verified = 0
    model.verified?.should == false
    model.verified = true
    model.verified?.should == true
    model.verified = nil
    model.verified?.should == false
  end
  
  it "should convert values to array" do
    model = JsonRecord::Test::Model.new
    model.strings = "a"
    model.strings.should == ["a"]
    model.strings = ["a", "b"]
    model.strings.should == ["a", "b"]
  end
  
  it "should convert values to BigDecimal" do
  	model = JsonRecord::Test::Model.new
  	model.price = '5.55'
  	model.price.should == BigDecimal.new('5.55')
  end
  
  it "should convert a hash to an embedded document" do
    model = JsonRecord::Test::Model.new
    model.primary_trait = {:name => "thing", :value => "stuff"}
    model.primary_trait.name.should == "thing"
    model.primary_trait.value.should == "stuff"
    model.primary_trait.attributes.should == {"name" => "thing", "value" => "stuff"}
  end
  
  it "should not convert values that are already of the right class" do
    model = JsonRecord::Test::Model.new
    model.map = {:name => "thing", :value => "stuff"}
    model.map.should == {:name => "thing", :value => "stuff"}
  end
  
  it "should leave a value unconverted if it can't be converted" do
    model = JsonRecord::Test::Model.new
    model.value = "foo"
    model.value.should == "foo"
    model.price = "expensive"
    model.price.should == "expensive"
    model.when = "now"
    model.when.should == "now"
    model.verified_at = "2001-100-100"
    model.verified_at.should == "2001-100-100"
    model.viewed_at = "the year 2000"
    model.viewed_at.should == "the year 2000"
    lambda{model.primary_trait = "stuff"}.should raise_error(ArgumentError)
  end
  
  it "should mix the json attributes into the regular attribute minus the json field itself" do
    model = JsonRecord::Test::Model.new(:string_field => "test")
    model.name = "test name"
    model.value = 1
    attrs = model.attributes
    attrs["string_field"].should == "test"
    attrs["name"].should == "test name"
    attrs["value"].should == 1
    attrs.should_not include("json")
  end
  
  it "should use default values if a value has not been set" do
    model = JsonRecord::Test::Model.new
    model.value.should == 0
    model.value = nil
    model.value.should == 0
  end
  
  it "should initialize json attributes with blank values" do
    JsonRecord::Test::Model.new.attributes.should == {
      "name"=>nil,
      "price"=>nil,
      "ratio"=>nil,
      "string_field"=>nil,
      "verified_at"=>nil,
      "viewed_at"=>nil,
      "field_1"=>nil,
      "field_2"=>nil,
      "field_3"=>nil,
      "field_4"=>nil,
      "field_5"=>nil,
      "unit_price"=>nil,
      "unit_ratio"=>nil,
      "traits"=>[],
      "value"=>0,
      "strings"=>[],
      "map"=>{},
      "verified"=>nil,
      "when"=>nil,
      "primary_trait"=>nil,
      "dimension"=>nil
    }
    JsonRecord::Test::Model.new.attributes["traits"].should be_a(JsonRecord::EmbeddedDocumentArray)
  end
  
  it "should make default values automatically for arrays and hashes" do
    model_1 = JsonRecord::Test::Model.new
    model_1.strings << "val"
    model_1.strings.should == ["val"]
    model_1.map["val"] = 1
    model_1.map.should == {"val" => 1}
    model_2 = JsonRecord::Test::Model.new
    model_2.strings << "val2"
    model_2.strings.should == ["val2"]
    model_2.map["val2"] = 2
    model_2.map.should == {"val2" => 2}
  end
  
  it "should allow mass assignment of json attributes" do
    model = JsonRecord::Test::Model.new(:name => "test name", :string_field => "test string_field", :price => "1")
    model.name.should == "test name"
    model.string_field.should == "test string_field"
    model.price.should == 1.0
  end
  
  it "should deserialize JSON in a json field into the attributes" do
    model = JsonRecord::Test::Model.new(:json => '{"name": "test name", "value": 1}')
    model.name.should == "test name"
    model.value.should == 1
  end
  
  it "should reserialize json attributes into a JSON field" do
    model = JsonRecord::Test::Model.new(:name => "test name", :value => 1)
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1}
    model.value = 2
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 2}
  end
  
  it "should keep undefined keys found in the JSON field" do
    model = JsonRecord::Test::Model.new(:json => '{"name": "test name", "value": 1, "unknown": "my value", "other stuff": {"value": 2}, "primary_trait": {"name": "n1", "stuff": true}}')
    model.save!
    model.value = 2
    model.primary_trait.value = "beans"
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1, "unknown" => "my value", "other stuff" => {"value" => 2}, "primary_trait" => {"name" => "n1", "stuff" => true, "sub_traits" => []}}
    model = JsonRecord::Test::Model.find(model.id)
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1, "unknown" => "my value", "other stuff" => {"value" => 2}, "primary_trait" => {"name" => "n1", "stuff" => true, "sub_traits" => []}}
    model.attributes.should_not include("other stuff")
    model.should_not respond_to(:other_stuff)
    model.primary_trait.attributes.should_not include("stuff")
  end
  
  it "should allow multiple JSON fields" do
    model = JsonRecord::Test::Model.new(:name => "test name", :value => 1, :field_1 => "one")
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.name.should == "test name"
    model.field_1.should == "one"
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1}
    ActiveSupport::JSON.decode(Zlib::Inflate.inflate(model.compressed_json)).should == {"field_1" => "one"}    
  end
  
  it "should have json attributes inherited by subclasses" do
    model = JsonRecord::Test::Model.new(:name => "test name")
    model.respond_to?(:another_field).should == false
    sub_model = JsonRecord::Test::SubModel.new(:name => "test name", :another_field => "woo")
    sub_model.another_field.should == "woo"
    sub_model.save!
    sub_model = JsonRecord::Test::SubModel.find(sub_model.id)
    sub_model.another_field.should == "woo"
  end
  
  it "should track changes on json attributes" do
    model = JsonRecord::Test::Model.new(:name => "test name", :primary_trait => {:name => "n1", :value => "v1"})
    model.changes.should == {"name" => [nil, "test name"]}
    model.primary_trait.changes.should == {"name" => [nil, "n1"], "value" => [nil, "v1"]}
    model.save!
    model.changes.should == {}
    
    model.reload
    model.changes.should == {}
    model.primary_trait.name.should == "n1"
    model.name = "new name"
    model.value = 1
    model.primary_trait = {:name => "n2", :value => "v2"}
    
    model.changes.should == {"name" => ["test name", "new name"], "value" => [0, 1]}
    model.name_changed?.should == true
    model.name_was.should == "test name"
    model.name_change.should == ["test name", "new name"]
    model.name = "test name"
    model.changes.should == {"value" => [0, 1]}
    model.name_changed?.should be_blank
    model.name_was.should == "test name"
    model.name_change.should == nil
  end
  
  it "should validate the presence of a json attribute" do
    model = JsonRecord::Test::Model.new
    model.valid?.should == false
    model.errors[:name].should_not be_blank
    model.name = "woo"
    model.valid?.should == true
  end
  
  it "should validate the length of a json attribute" do
    model = JsonRecord::Test::Model.new(:name => "this name value is way too long", :field_4 => "a", :field_5 => "b")
    model.valid?.should == false
    model.errors[:name].should_not be_blank
    model.errors[:field_4].should_not be_blank
    model.errors[:field_5].should_not be_blank
    model.name = "shorter name"
    model.field_4 = "a much longer name that won't fit"
    model.field_5 = "a much longer name that will fit because it is OK"
    model.valid?.should == false
    model.errors[:name].should be_blank
    model.errors[:field_4].should_not be_blank
    model.errors[:field_5].should be_blank
    model.field_4 = "just right"
    model.valid?.should == true
  end
  
  it "should validate the type of a json attribute" do
    model = JsonRecord::Test::Model.new(:name => "test name", :value => "purple", :price => "free", :when => "2010-40-52", :verified_at => "2010-40-50T00:00:00", :viewed_at => "2010-02-01T00:90:00")
    model.valid?.should == false
    model.errors[:value].should_not be_blank
    model.errors[:price].should_not be_blank
    model.errors[:when].should_not be_blank
    model.errors[:verified_at].should_not be_blank
    model.errors[:viewed_at].should_not be_blank
    model.value = "1"
    model.price = "100"
    model.when = "2010-02-01"
    model.verified_at = Time.now.to_s
    model.viewed_at = DateTime.now.to_s
    model.valid?.should == true
  end
  
  it "should validate that a json attribute is in a range" do
    model = JsonRecord::Test::Model.new(:name => "test name", :field_3 => "Z")
    model.valid?.should == false
    model.errors[:field_3].should_not be_blank
    model.field_3 = "B"
    model.valid?.should == true
  end
  
  it "should validate the format of a json attribute" do
    model = JsonRecord::Test::Model.new(:name => "test name", :field_2 => "ABC")
    model.valid?.should == false
    model.errors[:field_2].should_not be_blank
    model.field_2 = "abc"
    model.valid?.should == true
  end
  
  it "should reload the json attributes when the record is reloaded" do
    model = JsonRecord::Test::Model.new(:name => "test name", :field_1 => "ABC")
    model.save!
    model.name = "new name"
    model.field_1 = "abc"
    model.name.should == "new name"
    model.field_1.should == "abc"
    model.reload
    model.name.should == "test name"
    model.field_1.should == "ABC"
  end
  
  it "should compress data if it is stored in a binary column" do
    model = JsonRecord::Test::Model.new(:name => "test", :field_1 => "one", :field_2 => "two")
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.field_1.should == "one"
    model.field_2.should == "two"
    ActiveSupport::JSON.decode(Zlib::Inflate.inflate(model.compressed_json)).should == {"field_1" => "one", "field_2" => "two"}
  end
  
  it "should handle embedded documents" do
    model = JsonRecord::Test::Model.new(:name => "test", :primary_trait => {:name => "primary", :value => "primary value"})
    model.primary_trait.name.should == "primary"
    model.primary_trait.value.should == "primary value"
    model.primary_trait.parent.should == model
    
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.primary_trait.name.should == "primary"
    model.primary_trait.value.should == "primary value"
    model.primary_trait.parent.should == model
    
    model.primary_trait = JsonRecord::Test::Trait.new(:name => "new", :value => "val")
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.primary_trait.name.should == "new"
    model.primary_trait.value.should == "val"
    model.primary_trait.parent.should == model
  end
  
  it "should handle many embedded documents" do
    model = JsonRecord::Test::Model.new(:name => "test", :traits => [{:name => "n1", :value => "v1"}, {:name => "n2", :value => "v2"}])
    model.traits.build(:name => "n3", :value => "v3")
    model.traits.build(JsonRecord::Test::Trait.new(:name => "n4", :value => "v4"))
    model.traits << {"name" => "n5", "value" => "v5"}
    model.traits << JsonRecord::Test::Trait.new("name" => "n6", "value" => "v6")
    model.traits.concat([{"name" => "n7", "value" => "v7"}, {:name => "n8", :value => "v8"}, JsonRecord::Test::Trait.new("name" => "n9", "value" => "v9")])
    model.traits.collect{|t| [t.name, t.value]}.should == [["n1", "v1"], ["n2", "v2"], ["n3", "v3"], ["n4", "v4"], ["n5", "v5"], ["n6", "v6"], ["n7", "v7"], ["n8", "v8"], ["n9", "v9"]]
    model.traits.collect{|t| t.parent}.uniq.should == [model]
    
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.traits.collect{|t| [t.name, t.value]}.should == [["n1", "v1"], ["n2", "v2"], ["n3", "v3"], ["n4", "v4"], ["n5", "v5"], ["n6", "v6"], ["n7", "v7"], ["n8", "v8"], ["n9", "v9"]]
    model.traits.collect{|t| t.parent}.uniq.should == [model]
    
    model.traits.slice!(0)
    model.traits.pop
    model.traits = model.traits.reverse
    model.traits[1].name = "name7"
    model.traits[1].value = "value7"
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.traits.collect{|t| [t.name, t.value]}.should == [["n8", "v8"], ["name7", "value7"], ["n6", "v6"], ["n5", "v5"], ["n4", "v4"], ["n3", "v3"], ["n2", "v2"]]
  end
  
  it "should handle nested embedded documents" do
    model = JsonRecord::Test::Model.new(:name => "test")
    trait = model.traits.build(:name => "n1", :value => "v1")
    subtrait = trait.sub_traits.build(:name => "s1", :value => "v1")
    model.traits.should == [trait]
    model.traits.first.sub_traits.should == [subtrait]
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
  end
  
  it "should be able to set a many key with the values in a hash" do
    model = JsonRecord::Test::Model.new(:name => "test")
    model.traits = {"first" => {:name => "n1", :value => "v1"}, "second" => {:name => "n2", :value => "v2"}}
    model.traits.size.should == 2
    model.traits.collect{|t| t.name}.sort.should == ["n1", "n2"]
  end
  
  it "should get the json field definition for a field" do
    json_field, field = JsonRecord::Test::Model.json_field_definition(:value)
    json_field.should == "json"
    field.name.should == "value"
    
    json_field, field = JsonRecord::Test::Model.json_field_definition("field_1")
    json_field.should == "compressed_json"
    field.name.should == "field_1"
    
    json_field, field = JsonRecord::Test::Model.json_field_definition("nothing")
    json_field.should == nil
    field.should == nil
  end
  
  it "should validate uniqueness of embedded documents" do
    model = JsonRecord::Test::Model.new(:name => "test", :traits => [{:name => "n1", :value => "v1"}, {:name => "n1", :value => "v2"}])
    model.valid?.should == false
    model.errors[:traits].should_not be_blank
    model.traits.first.errors[:name].should be_blank
    model.traits.last.errors[:name].should_not be_blank
    
    model.traits.last.name = "n2"
    model.valid?.should == true
    model.errors[:traits].should be_blank
    model.traits.first.errors[:name].should be_blank
    model.traits.last.errors[:name].should be_blank
  end
  
  it "should perform validations on embedded documents" do
    model = JsonRecord::Test::Model.new(:name => "test")
    model.primary_trait = {:name => "", :value => "v2"}
    trait = model.traits.build(:value => "v1")
    subtrait = trait.sub_traits.build(:name => "s1", :count => "plaid")
    model.valid?.should == false
    model.errors[:primary_trait].should_not be_blank
    model.errors[:traits].should_not be_blank
    model.primary_trait.errors[:name].should_not be_blank
    trait.errors[:name].should_not be_blank
    trait.errors[:sub_traits].should_not be_blank
    subtrait.errors[:count].should_not be_blank
    
    model.primary_trait.name = "p1"
    trait.name = "n1"
    subtrait.count = 1
    model.valid?.should == true
    model.errors[:primary_trait].should be_blank
    model.errors[:traits].should be_blank
    model.primary_trait.errors[:name].should be_blank
    trait.errors[:name].should be_blank
    trait.errors[:sub_traits].should be_blank
    subtrait.errors[:count].should be_blank
  end
  
  it "should perform validation callbacks on embedded documents" do
    trait = JsonRecord::Test::Trait.new(:name => "name")
    trait.valid?.should == true
    trait.callbacks.should == [:before_validation, :after_validation]
  end
  
  it "should allow overriding the attribute reader and writers" do
    model = JsonRecord::Test::Model.new(:unit_price => :infinity)
    model.unit_price.should == 1000000000
    model.unit_price = 1.2253
    model.unit_price.should == 1.23
  end
end
