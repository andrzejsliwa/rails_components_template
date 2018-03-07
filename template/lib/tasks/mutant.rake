
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
