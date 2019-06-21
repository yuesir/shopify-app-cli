# frozen_string_literal: true
# rubocop: disable Style/MethodMissingSuper
# rubocop: disable Style/MissingRespondToMissing

require_relative 'sorbet_plugin'

module ConstMissing
  def self.stub
    Class.new do
      def initialize(*)
      end

      def self.method_missing(*)
        self.class.new
      end

      def method_missing(*)
        self.class.new
      end

      def self.const_missing(_)
        self.class.new
      end
    end
  end
end

class Object
  def self.method_missing(*)
    ConstMissing.stub
  end

  def self.const_missing(name)
    const_set(name, ConstMissing.stub)
  end
end

class Numeric
  def method_missing(*)
    ConstMissing.stub
  end
end

module SorbetPlugins
  module SmartProperties
    def self.property!(name, options = {})
      property(name, options.merge(required: true))
    end

    def self.property(name, options = {})
      reader_name = options.key?(:reader) ? options[:reader] : name

      puts <<~RUBY
        def #{reader_name}; end
        def #{name}=(#{name}); end
      RUBY
    end

    def self.const_missing(name)
      const_set(name, ConstMissing.stub)
    end

    _, _, source = SorbetPlugins.parse_args
    instance_eval(source)
  end
end
