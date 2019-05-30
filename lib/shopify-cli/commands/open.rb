require 'shopify_cli'

module ShopifyCli
  module Commands
    class Open < ShopifyCli::Command
      def call(*)
        ShopifyCli::Tasks::Tunnel.call(@ctx)
        @ctx.system("open https://tb-test.myshopify.com/admin/apps/1f64cf4a4eb0056f7175b6498c2270bd")
      end

      def self.help
        <<~HELP
          Open your app in the browser
          Usage: {{command:#{ShopifyCli::TOOL_NAME} open}}
        HELP
      end
    end
  end
end
