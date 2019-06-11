require 'shopify_cli'

module ShopifyCli
  module Tasks
    class Clone < ShopifyCli::Task
      def call(*args)
        repository = args.shift
        dest = args.shift
        CLI::UI::Frame.open("Cloning into #{dest}...") do
          git_progress('clone', '--single-branch', repository, dest)
        end
      end

      def git_progress(*git_command)
        CLI::UI::Progress.progress do |bar|
          output, status = CLI::Kit::System.capture2e('git', *git_command, '--progress') do |_out, err|
            unless status.success?
             puts out
            end
              next unless output.strip.start_with?('Receiving objects:')
              percent = (output.match(/Receiving objects:\s+(\d+)/)[1].to_f / 100).round(2)
              bar.tick(set_percent: percent)
            bar.tick(set_percent: 1.0)
            true
          end
        end
      end
    end
  end
end