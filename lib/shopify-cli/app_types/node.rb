require 'shopify_cli'

module ShopifyCli
  module AppTypes
    class Node < AppType
      class << self
        def env_file(key, secret, host)
          <<~KEYS
            SHOPIFY_API_KEY=#{key}
            SHOPIFY_API_SECRET_KEY=#{secret}
            SHOPIFY_DOMAIN=myshopify.io
            HOST=#{host}
            PORT=8081
          KEYS
        end

        def description
          'node embedded app'
        end

        def callback_url(host)
          "#{host}/auth/callback"
        end

        def serve_command
          'npm run dev'
        end

        def generate
          {
            page: 'npm run-script generate-page',
          }
        end
      end

      def call(*args)
        @name = args.shift
        @ctx = args.shift
        @dir = File.join(Dir.pwd, @name)
        build
      end

      protected

      def build
        ShopifyCli::Tasks::Clone.call('git@github.com:shopify/webgen-embeddedapp.git', @name)
        CLI::Kit::System.system("git --git-dir ./#{@name}/.git reset --hard origin/configurable-domain")
        ShopifyCli::Finalize.request_cd(@name)
        ShopifyCli::Tasks::JsDeps.call(@dir)

        # temporary metadata construction, will be replaced by data from Partners
        @keys = Helpers::EnvFileHelper.new(self, @ctx)
        @keys.write('.env')
        remove_git_dir
        puts CLI::UI.fmt(post_clone)
      end

      def remove_git_dir
        git_dir = File.join(Dir.pwd, @name, '.git')
        if File.exist?(git_dir)
          FileUtils.rm_r(git_dir)
        end
      end

      def post_clone
        "Run {{command:#{ShopifyCli::TOOL_NAME} serve}} to start the app server"
      end
    end
  end
end
