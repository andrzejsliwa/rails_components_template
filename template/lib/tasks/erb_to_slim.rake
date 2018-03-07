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
