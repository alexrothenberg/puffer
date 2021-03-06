module Puffer
  module Controller
    module Config
      extend ActiveSupport::Concern

      included do
        puffer_class_attribute :group, :default
        puffer_class_attribute :model_name
        puffer_class_attribute :destroy, true

        helper_method :configuration
      end

      module InstanceMethods

        def configuration
          self.class.configuration
        end

      end

      module ClassMethods

        def puffer_class_attribute name, default = nil
          class_attribute "_puffer_attribute_#{name}"
          send "_puffer_attribute_#{name}=", default
        end

        def setup &block
          block.bind(Config.new(self)).call
        end

        def configuration
          @configuration ||= Config.new(self)
        end

      end

      class Config

        attr_accessor :controller

        def initialize controller
          @controller = controller
        end

        def method_missing method, *args, &block
          method_name = "_puffer_attribute_#{method}"
          if args.present? && controller.respond_to?("#{method_name}=")
            controller.send "#{method_name}=", args.first
          elsif controller.respond_to?(method_name)
            controller.send method_name
          else
            super
          end
        end

      end

    end
  end
end
