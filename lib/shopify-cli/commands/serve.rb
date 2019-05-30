# frozen_string_literal: true

require 'shopify_cli'

module ShopifyCli
  module Commands
    class Serve < ShopifyCli::Command
      def call(*)
        ShopifyCli::Tasks::Tunnel.call(@ctx)
        project = ShopifyCli::Project.current
        app_type = ShopifyCli::AppTypeRegistry[project.config["app_type"].to_sym]
        on_siginfo { %x(open "#{@ctx.app_metadata[:host]}/auth?shop=tb-test.myshopify.com") }
        exec(app_type.serve_command(@ctx))
      end

      def self.help
        <<~HELP
          Run your projects server.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} serve}}
        HELP
      end

      def on_siginfo
        fork do
          begin
            r, w = IO.pipe
            @signal = false
            trap('SIGINFO') do
              @signal = true
              w.write(0)
            end
            while r.read(1)
              next unless @signal
              @signal = false
              yield
            end
          rescue Interrupt
            exit(0)
          end
        end
      end
    end
  end
end
