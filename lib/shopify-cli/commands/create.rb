require 'shopify_cli'

module ShopifyCli
  module Commands
    class Create < ShopifyCli::Command
      prerequisite_task :tunnel

      def call(args, _name)
        @name = args.shift
        @partners = Helpers::API::Partners.new(@ctx)

        return puts CLI::UI.fmt(self.class.help) unless @name

        apps = @partners.get_apps
        @app = if apps.size > 1
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
        @ctx.log @app
        @partners.update_app_url(@app['apiKey'], @ngrok, app_type.callback_url(@ngrok))

        puts CLI::UI.fmt("{{yellow:*}} updated")

        return puts "not yet implemented" unless app_type

        # we need the concept of "project" probably to hold path state
        @ctx.root = File.join(Dir.pwd, @name)

        AppTypeRegistry.build(app_type, @name, @ctx)

        ShopifyCli::Project.write(@ctx, app_type)
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
