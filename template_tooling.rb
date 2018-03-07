def add_template_repository_to_source_path
  source_paths.unshift(File.dirname(__FILE__))
end

def assert_minimum_rails_version(minimum_version = "~> 5.2.0.rc1")
  requirement = Gem::Requirement.new(minimum_version)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{minimum_version}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end
