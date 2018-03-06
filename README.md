## Rails Application Template with Komponent.io and other opinionated decisions

```bash
$ rvm 2.5.0
$ git clone git@github.com:andrzejsliwa/rails_components_template.git ~/.rails_components_template
$ ln -s ~/.rails_components_template/.railsrc ~/.railsrc
$ rails new someapp
$ cd someapp
$ foreman start -f Procfile.dev  
```
## Batteries included ;)

* removed sprockets and replaced it with webpacker
* moved app/script to frontend, and applied on it komponent.io with support for stimulus
* configured webpacker to point with source_path to frontend directory
* switched from include tag to pack tags
* moved turbolinks (with leaving gem for rails integration on redirecting), actioncable, rails-ujs to yarn
* prepended view path with frontend for komponents views 
* configured komponent in application.rb and in controller
* added cable.js to frontend directory
* replaced sass with postcss
* added postcss-import, postcss-cssnext, postcss-nested (with support for BEM)
* added stylelint with configuration
* added normalize.css
* configured lint-staged (with runing eslint with airbnb defaults + rubocop for ruby)
* connected lint-staged to pre-commit hooks
* added foreman with default Procfile (for heroku) and Procfile.dev for development
* added custom user handling for postgres via ENV variable
* added support for .env via dotenv-rails
* allow webpack-dev-server host as allowed origin for connect-src in content_security_policy
* added browserlint with nice defaults
* replaced erb with slim for templates
* added task for conversion of erb -> slim (with html2slim gem)
* added rake hook for assets:precompile to handle yarn and webpacker compilation on heroku
* turn on gem for redis (action cable)
* added guard with extensions (migrations, rspec, rubocop, shell, spring)
* added guard configuration
* added pry with extensions (rescue, byebug)
* added factory_bot_rails as replacement for fixtures
* added faker for generating fake data in specs
* added & configured annotate (database structure annotations in models)
* added awesome_print for rails console
* replaced standard tests with rspec
* enabled support for system specs in rails_helper
* added missing generator for system spec
* added selenium-webdriver to drive system spec
* added oop-interface for real interfaces (with narrowing scope)
* added methods for making referencing methods in Ruby easy 
* added airbrake & newrelic_rpm for error handling and monitoring

