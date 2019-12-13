require 'shopify_cli'

module ShopifyCli
  module Commands
    class Create
      class Project < ShopifyCli::SubCommand
        include Helpers::OS

        options do |parser, flags|
          parser.on('--title=TITLE') { |t| title[:title] = t }
          parser.on('--type=TYPE') { |t| flags[:type] = t.downcase.to_sym }
          parser.on('--organization_id=ID') { |url| flags[:organization_id] = url }
          parser.on('--shop_domain=MYSHOPIFYDOMAIN') { |url| flags[:shop_domain] = url }
        end

        class BadGateway < StandardError; end

        def call(args, _name)
          form = Forms::CreateApp.ask(@ctx, args, options.flags)
          return @ctx.puts(self.class.help) if form.nil?

          AppTypeRegistry.check_dependencies(form.type, @ctx)
          AppTypeRegistry.build(form.type, form.name, @ctx)
          ShopifyCli::Project.write(@ctx, form.type)

          api_client = Tasks::CreateApiClient.call(
            @ctx,
            org_id: form.organization_id,
            title: form.title,
            app_url: 'https://shopify.github.io/shopify-app-cli/getting-started',
          )

          Helpers::EnvFile.new(
            api_key: api_client["apiKey"],
            secret: api_client["apiSecretKeys"].first["secret"],
            shop: form.shop_domain,
            scopes: 'write_products,write_customers,write_draft_orders',
          ).write(@ctx)

          dashboard_url = "https://partners.shopify.com/#{form.organization_id}/apps/#{api_client['id']}"

          @ctx.puts("{{v}} {{green:#{form.title}}} was created in your Partner" \
                    " Dashboard " \
                    "{{underline:#{dashboard_url}}")
          @ctx.puts("{{v}} {{green:#{form.title}}} is ready to install on " \
                    "{{green:#{form.shop_domain}}}") unless form.shop_domain.nil?

          Helpers::Async.in_thread do
            @ctx.capture2(ShopifyCli::Project.at(@ctx.root).app_type.serve_command(@ctx), chdir: @ctx.root)
          end

          spinner = CLI::UI::Spinner::Async.start(
            "Opening your Partner Dashboard to install your app on your Dev Store"
          )
          CLI::Kit::Util.begin do
            uri = URI.parse(Tasks::Tunnel.call(@ctx))
            http = ::Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            req = ::Net::HTTP::Get.new(uri.request_uri)
            response = http.request(req)
            raise BadGateway if response.code.to_i == 502
          end.retry_after(BadGateway, retries: 10) do
            @ctx.pause(10)
          end

          spinner.stop

          open_url!(@ctx, "#{dashboard_url}/test")
        end

        def self.help
          <<~HELP
            Create a new app project.
              Usage: {{command:#{ShopifyCli::TOOL_NAME} create project <appname>}}
          HELP
        end
      end
    end
  end
end
