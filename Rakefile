require 'rubygems'
require 'rake'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

begin
  require 'spec/rake/spectask'
  desc 'Test json_record.'
  Spec::Rake::SpecTask.new(:test) do |t|
    t.spec_files = FileList.new('spec/**/*_spec.rb')
  end
rescue LoadError
  tast :test do
    STDERR.puts "You must have rspec >= 1.2.9 to run the tests"
  end
end

desc 'Generate documentation for json_record.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options << '--title' << 'JSON Record' << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "json_record"
    gem.summary = %Q{ActiveRecord support for mapping complex documents in a single RDBMS row via JSON serialization.}
    gem.email = "brian@embellishedvisions.com"
    gem.homepage = "http://github.com/bdurand/json_record"
    gem.authors = ["Brian Durand"]
  
    gem.add_dependency('activerecord', '>= 2.2.2')
    gem.add_development_dependency('rspec', '>= 1.2.9')
    gem.add_development_dependency('jeweler')
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
end