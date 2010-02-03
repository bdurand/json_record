module JsonRecord
  module Test
    def self.create_tables
      db_dir = File.expand_path(File.join(__FILE__, '..', 'tmp'))
      Dir.mkdir(db_dir) unless File.exist?(db_dir)
      db = File.join(db_dir, 'test_JsonRecord.sqlite3')
      Model.establish_connection("adapter" => "sqlite3", "database" => db)
      
      Model.connection.create_table(:models) do |t|
        t.text :json
        t.binary :compressed_json
        t.string :string_field
      end unless Model.table_exists?
      
      SubModel.connection.create_table(:sub_models) do |t|
        t.text :json
        t.binary :compressed_json
        t.string :string_field
      end unless SubModel.table_exists?
    end
    
    def self.drop_tables
      db_dir = File.expand_path(File.join(__FILE__, '..', 'tmp'))
      db = File.join(db_dir, 'test_JsonRecord.sqlite3')
      Model.connection.disconnect!
      File.delete(db) if File.exist?(db)
      Dir.delete(db_dir) if File.exist?(db_dir) and Dir.entries(db_dir).reject{|f| f.match(/^\.+$/)}.empty?
    end

    class Trait < JsonRecord::EmbeddedDocument
      key :name, :required => true
      key :value
      key :count, Integer
      many :sub_traits, Trait, :unique => [:name, :value]
    end
    
    class Model < ActiveRecord::Base
      include JsonRecord::Serialized
      serialize_to_json(:json) do |schema|
        schema.key :name, String, :required => true, :length => 15
        schema.key :value, Integer, :default => 0
        schema.key :price, Float
        schema.key :verified, Boolean
        schema.key :when, Date
        schema.key :verified_at, Time
        schema.key :viewed_at, DateTime
        schema.key :strings, Array
        schema.key :map, Hash
        schema.key :primary_trait, Trait
        schema.many :traits, Trait, :unique => :name
      end

      serialize_to_json(:compressed_json) do |schema|
        schema.key :field_1
        schema.key :field_2, :format => /^[a-z]+$/
        schema.key :field_3, :in => ("A".."M")
        schema.key :field_4, :length => (4..15)
        schema.key :field_5, :length => {:minimum => 5}
      end
    end
    
    class SubModel < Model
      set_table_name :sub_models
      
      serialize_to_json(:json) do |schema|
        schema.key :another_field
      end
    end
  end
end
