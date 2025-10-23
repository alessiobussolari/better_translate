# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Type checking with Steep
desc "Run type checking with Steep"
task :steep do
  sh "bundle exec steep check"
end

# Security scanning with Brakeman
desc "Run security scanning with Brakeman"
task :brakeman do
  require "brakeman"
  result = Brakeman.run(
    app_path: ".",
    print_report: true,
    pager: false,
    force_scan: true
  )
  exit Brakeman::Warnings_Found_Exit_Code unless result.filtered_warnings.empty?
end

task default: %i[spec rubocop steep brakeman]
