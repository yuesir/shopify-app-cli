module ShopifyCli
  module Helpers
    module OS
      OPEN_COMMANDS = {
        'open' => 'open',
        'xdg-open' => 'xdg-open',
        'rundll32' => 'rundll32 url.dll,FileProtocolHandler',
        'python' => 'python -m webbrowser',
      }

      def os
        return :mac if mac?
        return :linux if linux?
      end

      def mac?
        /Darwin/.match(uname)
      end

      def linux?
        /Linux/.match(uname)
      end

      def uname(flag: 'a')
        @uname ||= CLI::Kit::System.capture2("uname -#{flag}")[0].strip
      end

      def open_url!(ctx, uri)
        OPEN_COMMANDS.each do |bin, cmd|
          path = which(bin)
          next if path.nil?
          return ctx.system(cmd, "'#{uri}'") if File.executable?(path)
        end
        help = <<~OPEN
          No open command available, (open, xdg-open, python)
          Please open {{bold_green:#{uri}}} in your browser
        OPEN
        ctx.puts(help)
      end

      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          end
        end
        nil
      end
    end
  end
end
