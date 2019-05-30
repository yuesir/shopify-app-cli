require 'shopify_cli'

module ShopifyCli
  module Commands
    class Populate < ShopifyCli::Command
      def call(*)
        spinner = CLI::UI::SpinGroup.new
        spinner.add('Adding 10 Products to my-dev-store') do |spin|
          sleep 5
          spin.update_title('Added 10 Products to my-dev-store')
        end
        spinner.wait
        # puts CLI::UI.fmt(self.class.mock)
      end

      def self.mock
        <<~MOCK
          Store populated with 10 products.
        MOCK
      end

      def self.help
        <<~HELP
          Populate dev store with products, customers and order records.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} populate <storename>}}
        HELP
      end
    end
  end
end
