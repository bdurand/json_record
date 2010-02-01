require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'test_models'))

describe JsonRecord::Serialized do
  before(:all) do
    @db_dir = File.expand_path(File.join(__FILE__, '..', 'tmp'))
    Dir.mkdir(@db_dir) unless File.exist?(@db_dir)
    @db = File.join(@db_dir, 'test_JsonRecord.sqlite3')
    JsonRecord::Test::Model.establish_connection("adapter" => "sqlite3", "database" => @db)
    JsonRecord::Test::Model.connection.create_table(:models) do |t|
      t.text :json
      t.binary :compressed_json
      t.string :string_field
    end unless JsonRecord::Test::Model.table_exists?
    JsonRecord::Test::SubModel.connection.create_table(:sub_models) do |t|
      t.text :json
      t.binary :compressed_json
      t.string :string_field
    end unless JsonRecord::Test::SubModel.table_exists?
  end
  
  after(:all) do
    JsonRecord::Test::Model.connection.disconnect!
    File.delete(@db)
    Dir.delete(@db_dir) if Dir.entries(@db_dir).reject{|f| f.match(/^\.+$/)}.empty?
  end
  
  it "should have accessors for json attributes" do
    model = JsonRecord::Test::Model.new
    model.name.should == nil
    model.name = "test"
    model.name.should == "test"
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
  
  it "should convert a hash to an embedded document" do
    model = JsonRecord::Test::Model.new
    model.primary_trait = {:name => "thing", :value => "stuff"}
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
    model.primary_trait = "stuff"
    model.primary_trait.should == "stuff"
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
      "string_field"=>nil,
      "verified_at"=>nil,
      "viewed_at"=>nil,
      "field_1"=>nil,
      "field_2"=>nil,
      "field_3"=>nil,
      "field_4"=>nil,
      "field_5"=>nil,
      "traits"=>[],
      "value"=>0,
      "strings"=>nil,
      "map"=>nil,
      "verified"=>nil,
      "when"=>nil,
      "primary_trait"=>nil
    }
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
    model.save
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1}
  end
  
  it "should keep undefined keys found in the JSON field" do
    model = JsonRecord::Test::Model.new(:json => '{"name": "test name", "value": 1, "unknown": "my value", "other stuff": {"value": 2}}')
    model.save!
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1, "unknown" => "my value", "other stuff" => {"value" => 2}}
    model = JsonRecord::Test::Model.find(model.id)
    ActiveSupport::JSON.decode(model.json).should == {"name" => "test name", "value" => 1, "unknown" => "my value", "other stuff" => {"value" => 2}}
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
    model = JsonRecord::Test::Model.create!(:name => "test name")
    model.changes.should == {}
    model.name = "new name"
    model.value = 1
    model.changes.should == {"name" => ["test name", "new name"], "value" => [0, 1]}
    model.name_changed?.should == true
    model.name_was.should == "test name"
    model.name_change.should == ["test name", "new name"]
    model.name = "test name"
    model.changes.should == {"value" => [0, 1]}
    model.name_changed?.should == false
    model.name_was.should == "test name"
    model.name_change.should == nil
  end
  
  it "should validate the presence of a json attribute"
  
  it "should validate the length of a json attribute"
  
  it "should validate that a json attribute is in a value"
  
  it "should validate the type of a json attribute"
  
  it "should validate that a json attribute is in a range"
  
  it "should validate the format of a json attribute"
  
  it "should reload the json attributes when the record is reloaded"
  
  it "should save and find the record with no problems"
  
  it "should compress data if it is stored in a binary column" do
    model = JsonRecord::Test::Model.new(:name => "test", :field_1 => "one", :field_2 => "two")
    model.save!
    model = JsonRecord::Test::Model.find(model.id)
    model.field_1.should == "one"
    model.field_2.should == "two"
    ActiveSupport::JSON.decode(Zlib::Inflate.inflate(model.compressed_json)).should == {"field_1" => "one", "field_2" => "two"}
  end
  
  it "should handle nested embedded documents"
  
end
