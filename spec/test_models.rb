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

    class Trait
      include JsonRecord::EmbeddedDocument
      schema.key :name, :required => true
      schema.key :value
      schema.key :count, Integer
      schema.many :sub_traits, Trait, :unique => [:name, :value]
      
      attr_accessor :callbacks
      before_validation{|record| record.callbacks ||= []; record.callbacks << :before_validation}
      after_validation{|record| record.callbacks ||= []; record.callbacks << :after_validation}
    end
    
    class Dimension
      include JsonRecord::EmbeddedDocument
      schema.key :height, Integer, :required => true
      schema.key :width, Integer, :required => true
      attr_accessor :unit
      
      def height= (value)
        if value == :infinity
          self[:height] = 1000000000
        else
          self[:height] = value
        end
      end
    end
    
    class Model < ActiveRecord::Base
      serialize_to_json(:json) do |schema|
        schema.key :name, String, :required => true, :length => 15
        schema.key :value, Integer, :default => 0
        schema.key :price, Float
        schema.key :ratio, BigDecimal
        schema.key :verified, Boolean
        schema.key :when, Date
        schema.key :verified_at, Time
        schema.key :viewed_at, DateTime
        schema.key :strings, Array
        schema.key :map, Hash
        schema.key :primary_trait, Trait
        schema.many :traits, Trait, :unique => :name
        schema.key :dimension, Dimension
      end

      serialize_to_json(:compressed_json) do |schema|
        schema.key :field_1
        schema.key :field_2, :format => /^[a-z]+$/
        schema.key :field_3, :in => ("A".."M")
        schema.key :field_4, :length => (4..15)
        schema.key :field_5, :length => {:minimum => 5}
        schema.key :unit_price, Float
        schema.key :unit_ratio, BigDecimal
      end
      
      def unit_price
        p = self[:price]
        p.is_a?(Numeric) ? (p * 100).round / 100.0 : p
      end
      
      def unit_price= (value)
        value = 1000000000 if value == :infinity
        self[:price] = value
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
