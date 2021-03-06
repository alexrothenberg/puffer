require 'kaminari'

require 'orm_adapter'
require 'puffer/orm_adapter/base'
require 'puffer/orm_adapter/active_record' if defined?(ActiveRecord::Base::OrmAdapter)
require 'puffer/orm_adapter/mongoid' if defined?(Mongoid::Document::OrmAdapter)
#require 'puffer/orm_adapter/data_mapper' if defined?(DataMapper::Resource::OrmAdapter)
#require 'puffer/orm_adapter/mongo_mapper' if defined?(MongoMapper::Document::OrmAdapter)

require 'puffer/extensions/controller'
require 'puffer/extensions/core'
require 'puffer/extensions/mapper'
require 'puffer/extensions/form'
require 'puffer/extensions/directive_processor'
require 'puffer/extensions/engine'
require 'puffer/engine'

module Puffer

  class PufferError < StandardError
  end

  class ComponentMissing < PufferError
  end

  module Controller
    autoload :Action, 'puffer/controller/actions'
    autoload :MemberAction, 'puffer/controller/actions'
    autoload :CollectionAction, 'puffer/controller/actions'
  end
  
  module Component
    autoload :Base, 'puffer/component'
  end

  # Puffer has two types of mappings. If maps <tt>field.type</tt> to component
  # class and also maps field attributes to <tt>field.type</tt>
  mattr_accessor :_component_mappings
  self._component_mappings = {}

  # Maps <tt>field.type</tt> to component class
  #
  # ex:
  #
  #   Puffer.map_component :ckeditor, :rich, :text, :to => CkeditorComponent
  #
  # this declaration maps even text fields to use <tt>CkeditorComponent</tt> for
  # rendering
  def self.map_component *args
    to = args.extract_options![:to]
    args.each { |type| _component_mappings[type.to_sym] = to }
  end

  def self.component_for field
    type = field
    type = field.type if field.respond_to? :type
    (_component_mappings[type.to_sym] || "#{type}_component").to_s.camelize.constantize
  rescue NameError
    raise ComponentMissing, "Missing `#{type}` component for `#{field}` field. Please use Puffer.map_component binding or specify field type manually"
  end

  map_component :belongs_to, :has_one, :to => :ReferencesOneComponent
  map_component :has_many, :has_and_belongs_to_many, :to => :ReferencesManyComponent
  map_component :date, :time, :datetime, :date_time, :timestamp, :to => :DateTimeComponent
  map_component :integer, :float, :decimal, :big_decimal, :to => :StringComponent
  map_component :"mongoid/fields/serializable/object", :"bson/object_id", :symbol, :array, :hash, :set, :range, :to => :StringComponent




  mattr_accessor :_field_type_customs
  self._field_type_customs = []


  # Appends or prepends custom type.
  #
  # ex:
  #
  #   Puffer.append_custom_field_type :paperclip do |field|
  #     field.model.respond_to?(:attachment_definitions)
  #       && field.model.attachment_definitions.key?(:field.field_name.to_sym)
  #   end
  def self.prepend_custom_field_type custom_type, &block
    _field_type_customs.shift [custom_type, block]
  end

  def self.append_custom_field_type custom_type, &block
    _field_type_customs.push [custom_type, block]
  end

  def self.field_type_for field
    custom_type = swallow_nil{_field_type_customs.detect {|(type, block)| block.call(field) }.first}
    case custom_type
    when Proc then
      custom_type.call(field)
    else
      custom_type
    end
  end

  append_custom_field_type :select do |field|
    field.options.key? :select
  end
  append_custom_field_type :password do |field|
    field.name =~ /password/
  end
  append_custom_field_type(proc {|type| type.reflection.macro}) do |field|
    field.reflection
  end

end
