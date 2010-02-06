require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'jeweler'
require 'spec/rake/spectask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test json_record.'
Spec::Rake::SpecTask.new(:test) do |t|
  t.spec_files = FileList.new('spec/**/*_spec.rb')
end

desc 'Generate documentation for json_record.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options << '--title' << 'JSON Record' << '--line-numbers' << '--inline-source' << '--main' << 'README.rdoc'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Jeweler::Tasks.new do |gem|
  gem.name = "json_record"
  gem.summary = %Q{ActiveRecord support for mapping complex documents within a single RDBMS record via JSON serialization.}
  gem.email = "brian@embellishedvisions.com"
  gem.homepage = "http://github.com/bdurand/json_record"
  gem.authors = ["Brian Durand"]
  
  gem.add_dependency('activerecord', '>= 2.2.2', '< 3.0')
  gem.add_development_dependency('rspec', '>= 1.2.9')
  gem.add_development_dependency('jeweler')
end

Jeweler::GemcutterTasks.new
