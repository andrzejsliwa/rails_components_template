
class MutantRunner
  def run(targets = subjects)
    out = false
    Array(targets).each do |target|
      puts "Running mutant for '#{target}'"
      out = system("RAILS_EAGER_LOAD=true RAILS_ENV=test bundle exec mutant -r \
          ./config/environment #{ignored_subjects} --use rspec #{target}")
      break unless out
    end
    out
  end

  def subjects
    mutants_paths_path = Rails.root.join('.mutant_subjects')
    return [] unless File.exist?(mutants_paths_path)
    File.read(mutants_paths_path).split("\n").reject { |s| s.blank? }
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

  def camelize(string)
    mod_string = ''
    string.split('_').each do |part|
      mod_string += "#{part[0].upcase}#{part[1..-1]}"
    end
    mod_string
  end
end


namespace :mutate do
  runner = MutantRunner.new
  task :default do
    runner.run
  end

  runner.subjects.each do |subject|
    desc "Run mutation for #{subject}"
    task subject.to_sym do
      runner.run(subject)
    end
  end
end

desc "Run mutant for paths defined in `.mutant_subjects` and ignored subjects from `.mutant_ignored_subjects`"
task :mutate do
  Rake::Task['mutate:default'].invoke
end
