module JsonRecord
  module Test
    class Trait < JsonRecord::EmbeddedDocument
      key :name
      key :value
      many :sub_traits, :class_name => Trait
    end
    
    class Model < ActiveRecord::Base
      include JsonRecord::Serialized
      serialize_to_json(:json) do |schema|
        schema.key :name, String, :required => true
        schema.key :value, Integer, :default => 0
        schema.key :price, Float
        schema.key :verified, Boolean
        schema.key :when, Date
        schema.key :verified_at, Time
        schema.key :viewed_at, DateTime
        schema.key :strings, Array
        schema.key :map, Hash
        schema.key :primary_trait, Trait
        schema.many :traits, :class_name => Trait
      end

      serialize_to_json(:compressed_json) do |schema|
        schema.key :field_1
        schema.key :field_2
        schema.key :field_3
        schema.key :field_4
        schema.key :field_5
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
