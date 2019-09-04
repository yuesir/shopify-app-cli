# frozen_string_literal: true
require 'shopify_cli'
require 'optparse'
require 'forwardable'

module ShopifyCli
  class Options
    extend Forwardable
    include SmartProperties

    attr_reader :flags, :subcommand

    def_delegator :parser, :on, :on

    def initialize
      @flags = {}
    end

    def parse(options_block, args)
      @args = args
      parse_flags(options_block) if options_block.respond_to?(:call)
    end

    def parse_flags(block)
      block.call(parser, @flags)
      parser.parse!(@args)
    end

    def parser
      @parser ||= OptionParser.new
    end
  end
end
