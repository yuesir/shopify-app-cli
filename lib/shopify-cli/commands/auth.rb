require 'shopify_cli'

module ShopifyCli
  module Commands
    class Auth < ShopifyCli::Command
      def call(args, _name)
        auth = ShopifyCli::Helpers::Auth.new(@ctx)
        auth.authenticate
      end

      def self.help
        <<~HELP
          Authenticate an app.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} auth}}
        HELP
      end
    end
  end
end

