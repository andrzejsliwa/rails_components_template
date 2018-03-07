#
#
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
  gem 'mutant-rspec', git: 'git@github.com:mbj/mutant.git'
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

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => [:spec, :mutant]
rescue LoadError
  # no rspec available
end
},
  after: "require_relative 'config/application'\n"
)


insert_into_file(
  ".gitignore",
  %Q{.env\n},
  after: "\n"
)

run "rm -fr app/assets"

gsub_file(
  "app/views/layouts/application.html.erb",
  /javascript_include_tag\s+.application./,
  %Q{javascript_pack_tag 'application'}
)

gsub_file(
  "app/views/layouts/application.html.erb",
  /stylesheet_link_tag\s+.application.*%/,
  %Q{stylesheet_pack_tag 'application' %}
)

insert_into_file(
  "app/controllers/application_controller.rb",
  %Q{  prepend_view_path Rails.root.join("frontend")\n},
  after: "class ApplicationController < ActionController::Base\n"
)

file "Procfile", <<-PROCFILE
server: bin/rails server
PROCFILE

file "Procfile.dev", <<-PROCFILE
server: bin/rails server
assets: bin/webpack-dev-server
PROCFILE

file ".browserlistrc", <<-TXT
> 1%
TXT

file ".eslintrc", <<-JSON
{
  "extends": ["eslint-config-airbnb-base", "prettier"],
  "plugins": ["prettier"],
  "env": {
    "browser": true
  },
  "rules": {
    "prettier/prettier": "error",
    "class-methods-use-this": 1,
  },
  "parser": "babel-eslint",
  "settings": {
    "import/resolver": {
      "webpack": {
        "config": {
          "resolve": {
            "modules": ["frontend", "node_modules"]
          }
        }
      }
    }
  }
}
JSON

file ".stylelintrc", <<-JSON
{
  "extends": "stylelint-config-standard"
}
JSON

file ".rubocop.yml", <<-YML
AllCops:
  TargetRubyVersion: 2.5
  DisplayCopNames: true
  Exclude:
    - lib/tasks/*.rake
    - bin/update
    - bin/setup
    - config/environments/*
    - lib/tasks/erb_to_slim.rake
    - db/**/*
    - node_modules/**/*
    - Brewfile
    - Guardfile
    - .pryrc

Metrics/LineLength:
  Max: 120

Style/Documentation:
  Enabled: false
YML

insert_into_file "package.json", <<-JSON, after: %Q{"private": true,\n}
  "scripts": {
    "lint-staged": "$(yarn bin)/lint-staged"
  },
  "lint-staged": {
    "config/webpack/**/*.js": [
      "prettier --write",
      "eslint",
      "git add"
    ],
    "frontend/**/*.js": [
      "prettier --write",
      "eslint",
      "git add"
    ],
    "frontend/**/*.css": [
      "prettier --write",
      "stylelint --fix",
      "git add"
    ],
    "**/*.rb": [
      "rubocop --auto-correct --rails --color",
      "git add"
    ]
  },
  "pre-commit": [
    "lint-staged"
  ],
JSON

file "Guardfile",%q{
guard :spring, bundler: true do
  watch('Gemfile.lock')
  watch(%r{^config/})
  watch(%r{^spec/(support|factories)/})
  watch(%r{^spec/factory.rb})
end

group :red_green_refactor, halt_on_fail: true do
  # Note: The cmd option is now required due to the increasing number of ways
  #       rspec may be run, below are examples of the most common uses.
  #  * bundler: 'bundle exec rspec'
  #  * bundler binstubs: 'bin/rspec'
  #  * spring: 'bin/rspec' (This will use spring if running and you have
  #                          installed the spring binstubs per the docs)
  #  * zeus: 'zeus rspec' (requires the server to be started separately)
  #  * 'just' rspec: 'rspec'

  guard :rspec, cmd: 'bundle exec rspec' do
    require 'guard/rspec/dsl'
    dsl = Guard::RSpec::Dsl.new(self)

    # Feel free to open issues for suggestions and improvements

    # RSpec files
    rspec = dsl.rspec
    watch(rspec.spec_helper) { rspec.spec_dir }
    watch(rspec.spec_support) { rspec.spec_dir }
    watch(rspec.spec_files)

    # Ruby files
    ruby = dsl.ruby
    dsl.watch_spec_files_for(ruby.lib_files)

    # Rails files
    rails = dsl.rails(view_extensions: %w[erb haml slim])
    dsl.watch_spec_files_for(rails.app_files)
    dsl.watch_spec_files_for(rails.views)

    watch(rails.controllers) do |m|
      [
        rspec.spec.call("routing/#{m[1]}_routing"),
        rspec.spec.call("controllers/#{m[1]}_controller"),
        rspec.spec.call("acceptance/#{m[1]}")
      ]
    end

    # Rails config changes
    watch(rails.spec_helper)     { rspec.spec_dir }
    watch(rails.routes)          { "#{rspec.spec_dir}/routing" }
    watch(rails.app_controller)  { "#{rspec.spec_dir}/controllers" }

    # Capybara features specs
    watch(rails.view_dirs)     { |m| rspec.spec.call("features/#{m[1]}") }
    watch(rails.layouts)       { |m| rspec.spec.call("features/#{m[1]}") }

    # Turnip features and steps
    watch(%r{^spec/acceptance/(.+)\.feature$})
    watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$}) do |m|
      Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance'
    end
  end

  guard :rubocop, all_on_start: false, cli: %w[--rails --format clang --auto-correct] do
    watch(/.+\.rb$/)
    watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
  end
end

guard :migrate do
  watch(%r{^db/migrate/(\d+).+\.rb})
  watch('db/seeds.rb')
end
}



after_bundle do
  run "bin/spring stop"
  # https://github.com/rails/webpacker/issues/1303
  run "yarn add -D webpack-dev-server@^2.11.1"

  run "yarn add -D webpack-cli babel-eslint eslint eslint-config-airbnb-base eslint-config-prettier eslint-import-resolver-webpack eslint-plugin-import eslint-plugin-prettier lint-staged pre-commit prettier stylelint stylelint-config-standard"
  run "yarn add normalize.css postcss-nested postcss-inline-svg rails-ujs turbolinks actioncable"

  insert_into_file(
    ".postcssrc.yml",
    %Q{  postcss-nested: {}\n  postcss-inline-svg\n},
    after: "postcss-cssnext: {}\n"
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

  file "frontend/cable.js", <<-JAVASCRIPT
  import cable from "actioncable";

  let consumer;

  function createChannel(...args) {
    if (!consumer) {
      consumer = cable.createConsumer();
    }

    return consumer.subscriptions.create(...args);
  }

  export default createChannel;
  JAVASCRIPT

  file "frontend/packs/application.css", <<-CSS
  html, body {
    background: white; /* just an example */
  }
  CSS

  run "rm frontend/packs/application.js"
  file "frontend/packs/application.js", <<-JS
  import Turbolinks from "turbolinks";
  import Rails from "rails-ujs";
  import "components";

  import "./application.css";

  Turbolinks.start();
  Rails.start();
  JS

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

  file "lib/generators/rspec/system/system_generator.rb", %q{
  require 'generators/rspec'

  module Rspec
    module Generators
      # @private
      class SystemGenerator < Base
        source_root File.expand_path('templates', __dir__)
        class_option :system_specs, type: :boolean, default: true, desc: 'Generate system specs'

        def generate_feature_spec
          return unless options[:system_specs]

          template template_name, File.join('spec/system', class_path, filename)
        end

        def template_name
          'system_spec.rb.erb'
        end

        def filename
          "#{table_name}_spec.rb"
        end
      end
    end
  end
  }

  file "lib/generators/rspec/system/templates/system_spec.rb.erb", %q{
  require 'rails_helper'

  RSpec.describe "<%= class_name.pluralize %>", <%= type_metatag(:system) %> do
    before do
      driven_by(:rack_test)
    end

    pending "add some scenarios (or delete) #{__FILE__}"
  end
  }

  file "lib/tasks/mutant.rake", %q{

class MutantRunner
  def run
    out = false
    classes_list.each do |c|
      puts "Running mutant for '#{c}'"
      out = system("RAILS_EAGER_LOAD=true RAILS_ENV=test bundle exec mutant -r \
          ./config/environment #{ignored_subjects} --use rspec #{c}")
      break unless out
    end
    out
  end

  private

  def ignored_subjects
    ignored_subjects_path = Rails.root.join('.mutant_ignored_subjects')
    return "" unless File.exist?(ignored_subjects_path)
    File.read(ignored_subjects_path)
      .split("\n")
      .reject { |s| s.blank? }
      .map { |s| "--ignore-subject #{s}" }
      .join(" ")
  end

  def classes_list
    mutants_paths_path = Rails.root.join('.mutant_subjects')
    return [] unless File.exist?(mutants_paths_path)
    lines = File.read(mutants_paths_path).split("\n").reject { |s| s.blank? }
    paths, classes = lines.partition { |s| s =~ /\.rb/ }
    classes = lines.select { |s| s !~ /\.rb/ }
    Dir[*paths].map do |path|
      path.match(/(\w+).rb/)
    end.compact.each do |c|
      classes << camelize(c[1])
    end
    classes
  end

  def camelize(string)
    mod_string = ''
    string.split('_').each do |part|
      mod_string += "#{part[0].upcase}#{part[1..-1]}"
    end
    mod_string
  end
end

desc "Run mutant for paths defined in `.mutant_subjects` and ignored subjects from `.mutant_ignored_subjects`"
task :mutant do
  MutantRunner.new.run
end
  }

  file ".mutant_ignored_subjects", %q{
  Some#method
  }

  file ".mutant_subjects", %q{
  app/models/*.rb
  ApplicationController
  }

  file "lib/tasks/erb_to_slim.rake", %q{
  namespace :erb do
    desc 'Convert erb tempaltes to slim'
    task :to_slim do
      require 'html2slim'

      FileList[Rails.root.join('app/views/**/*.html.erb'),
               Rails.root.join('frontend/**/*.html.erb')].each do |erb|

        slim_output = erb.sub(/\.erb$/, '.slim')

        puts "conventing #{erb} .."
        File.open erb, 'r' do |f|
          content = HTML2Slim.convert!(f, :erb)
          IO.write(slim_output, content)
        end
        puts "converted to #{slim_output} ."
        File.delete(erb)
        puts "removed #{erb}"
      end
    end
  end
  }

  rails_command "db:create"
  rails_command "db:migrate"
  rails_command "erb:to_slim"

  run "rubocop --auto-correct --rails"

  git add: '-A .'
  git commit: '-m "Initial commit"'

  file ".env", <<-TXT
export USER=postgres

  TXT
end
