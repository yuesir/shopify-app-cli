require_relative 'bin/support/load_shopify'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.name = 'test:unit'
  t.libs += %w(test)
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = false
  t.warning = false
end

task :console do
  exec('irb', '-r', './bin/support/load_shopify.rb', '-r', 'byebug')
end

task :lint do
  exec('rubocop', '.')
end

task :test do
  [:lint, 'test:unit'].each { |t| build t }
end
