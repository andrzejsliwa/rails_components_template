ENV["DISABLE_BOOTSNAP"] = "1"
require_relative "template_tooling"
add_template_repository_to_source_path
assert_minimum_rails_version "~> 5.2.0.rc1"

gem 'redis', '~> 4.0'
gem 'komponent'
gem 'slim-rails'

gem 'oop-interface'
gem 'methods'

gem 'airbrake'
gem 'newrelic_rpm'

gem_group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'annotate'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'pry-rails'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'pry-rescue'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 3.7'
  # support for rspec 3.7 is not officially released
  gem 'mutant-rspec', github: 'mbj/mutant'
  gem 'selenium-webdriver'
  gem 'faker'
  gem 'awesome_print'
end

gem_group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'html2slim'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'guard-migrate'
  gem 'guard-rspec', require: false
  gem 'guard-rubocop'
  gem 'guard-shell'
  gem 'guard-spring'
  gem 'rubocop', require: false
  gem 'foreman'
  gem 'overcommit'
  gem 'fasterer'
  gem 'bundle-audit'
end

insert_into_file(
  "config/application.rb",
  %Q{
    config.komponent.root = Rails.root.join("frontend")

    config.i18n.available_locales = [:en]

    config.generators do |g|
      g.stylesheets     false
      g.javascripts     false
      g.helper          false
      g.channel         assets: false
      g.komponent stimulus: true, locale: true
    end},
  after: "config.load_defaults 5.2\n"
)

insert_into_file(
  "config/database.yml",
  %Q{  user: <%= ENV['USER'] %>\n},
  after: "adapter: postgresql\n"
)

insert_into_file(
  "config/initializers/content_security_policy.rb",
  %Q{
Rails.application.config.content_security_policy do |policy|
   policy.default_src :self, :https
   policy.font_src    :self, :https, :data
   policy.img_src     :self, :https, :data
   policy.object_src  :none
   policy.script_src  :self, :https
   policy.style_src   :self, :https, :unsafe_inline
   # You need to allow webpack-dev-server host as allowed origin for connect-src.
   policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

   # Specify URI for violation reports
   # policy.report_uri "/csp-violation-report-endpoint"
end
},
  after: "# Be sure to restart your server when you modify this file.\n"
)


insert_into_file(
  "Rakefile",
  %q{
Rake::Task.define_task('assets:precompile' => ['yarn:install', 'webpacker:compile'])

# rubocop:disable Lint/HandleExceptions
begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => [:spec, :mutant]
rescue LoadError
  # no rspec available
end
# rubocop:enable all
},
  after: "require_relative 'config/application'\n"
)


insert_into_file(
  ".gitignore",
  %Q{.env\n},
  after: "\n"
)

run "rm -fr app/assets"

insert_into_file(
  "app/controllers/application_controller.rb",
  %Q{  prepend_view_path Rails.root.join("frontend")\n},
  after: "class ApplicationController < ActionController::Base\n"
)

copy_file "template/Procfile", "Procfile"
copy_file "template/Procfile.dev", "Procfile.dev"
copy_file "template/.browserlistrc", ".browserlistrc"
copy_file "template/.eslintrc", ".eslintrc"
copy_file "template/.stylelintrc", ".stylelintrc"
copy_file "template/.rubocop.yml", ".rubocop.yml"

copy_file "template/Guardfile", "Guardfile"

after_bundle do
  run "bin/spring stop"
  # https://github.com/rails/webpacker/issues/1303
  run "yarn add -D webpack-dev-server@^2.11.1"

  run "yarn add -D webpack-cli git-guilt babel-eslint eslint eslint-config-airbnb-base eslint-config-prettier eslint-import-resolver-webpack eslint-plugin-import eslint-plugin-prettier prettier stylelint stylelint-config-standard"
  run "yarn add normalize.css postcss-nested postcss-inline-svg rails-ujs turbolinks actioncable"

  insert_into_file(
    ".postcssrc.yml",
    %Q{  postcss-nested: {}\n  postcss-inline-svg: {}\n},
    after: "postcss-cssnext: {}\n"
  )

  insert_into_file(
    "bin/setup", %q{
puts '== Installing overcommit =='
system!('bundle exec overcommit --install --force')
system!('bundle exec overcommit --sign')
},
    after: "# Add necessary setup steps to this file.\n"
  )

  gsub_file(
    "config/webpacker.yml",
    "source_path: app/javascript",
    "source_path: frontend"
  )

  gsub_file(
    "config/environments/development.rb",
    "config.eager_load = false",
    "config.eager_load = ENV['RAILS_EAGER_LOAD'] == 'true'"
  )

  gsub_file(
    "config/environments/test.rb",
    "config.eager_load = false",
    "config.eager_load = ENV['RAILS_EAGER_LOAD'] == 'true'"
  )

  run "mv app/javascript frontend"

  generate "komponent:install", "--stimulus"
  generate "rspec:install"
  generate "annotate:install"

  copy_file "template/frontend/cable.js", "frontend/cable.js"
  copy_file "template/frontend/packs/application.css", "frontend/packs/application.css"

  remove_file "frontend/packs/application.js"
  copy_file "template/frontend/packs/application.js", "frontend/packs/application.js"

  system_specs = <<-RUBY
      config.before(:each, type: :system) do
        driven_by :rack_test
      end

      config.before(:each, type: :system, js: true) do
        driven_by :selenium_chrome_headless
      end
  RUBY

  insert_into_file(
    "spec/rails_helper.rb",
    system_specs,
    after: "RSpec.configure do |config|\n"
  )

  copy_file "template/lib/generators/rspec/system/system_generator.rb",
            "lib/generators/rspec/system/system_generator.rb"
  copy_file "template/lib/generators/rspec/system/templates/system_spec.rb.erb",
            "lib/generators/rspec/system/templates/system_spec.rb.erb"

  copy_file "template/lib/tasks/mutant.rake", "lib/tasks/mutant.rake"
  copy_file "template/.mutant_ignored_subjects", ".mutant_ignored_subjects"
  copy_file "template/.mutant_subjects", ".mutant_subjects"
  copy_file "template/lib/tasks/erb_to_slim.rake", "lib/tasks/erb_to_slim.rake"

  copy_file "template/.overcommit.yml", ".overcommit.yml"
  copy_file "template/bin/rubocop_loop", "bin/rubocop_loop"

  rails_command "db:create"
  rails_command "db:migrate"
  rails_command "erb:to_slim"

  gsub_file(
    "app/views/layouts/application.html.slim",
    /javascript_include_tag\s+.application./,
    %Q{javascript_pack_tag 'application'}
  )

  gsub_file(
    "app/views/layouts/application.html.slim",
    /stylesheet_link_tag\s+.application./,
    %Q{stylesheet_pack_tag 'application'}
  )

  gsub_file(
    "app/views/layouts/mailer.html.slim",
    "      |  /* Email styles need to be inline */ ",
    "      |  /* Email styles need to be inline */"
  )

  run 'bundle exec overcommit --install --force'
  run 'bundle exec overcommit --sign'

  git add: '-A .'
  run 'bundle exec overcommit -r'
  git add: '-A .'
  git commit: '-m "Initial commit"'

  file ".env", <<-TXT
  TXT
end
