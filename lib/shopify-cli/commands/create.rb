require 'shopify_cli'

module ShopifyCli
  module Commands
    class Create < ShopifyCli::Command
      def call(args, _name)
        ShopifyCli::Tasks::Tunnel.call(@ctx)

        @name = args.shift
        @partners = Helpers::API::Partners.new(@ctx)

        return puts CLI::UI.fmt(self.class.help) unless @name

        apps = @partners.get_apps
        @app = @ctx.app_metadata = if apps.size > 1
          CLI::UI::Prompt.ask('Which app would you like to use?') do |handler|
            apps.each do |app|
              handler.option(app['title']) { app }
            end
          end
        else
          apps.first
        end

        app_type_id, app_type = CLI::UI::Prompt.ask('What type of app would you like to create?') do |handler|
          AppTypeRegistry.each do |identifier, type|
            handler.option(type.description) { [identifier, type] }
          end
        end

        puts CLI::UI.fmt("{{yellow:*}} updating app url")
        @ctx.log(@ctx.app_metadata)
        @partners.update_app_url(@app['apiKey'], @ctx.app_metadata[:host], app_type.callback_url(@ctx.app_metadata[:host]))

        puts CLI::UI.fmt("{{yellow:*}} updated")

        # we need the concept of "project" probably to hold path state
        @ctx.root = File.join(Dir.pwd, @name)

        AppTypeRegistry.build(app_type_id, @name, @ctx)

        ShopifyCli::Project.write(@ctx, app_type_id)
      end

      def self.help
        <<~HELP
          Bootstrap an app.
          Usage: {{command:#{ShopifyCli::TOOL_NAME} create <appname>}}
        HELP
      end
    end
  end
end
