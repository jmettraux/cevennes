
Gem::Specification.new do |s|

  s.name = 'cevennes'

  s.version = File.read(
    File.expand_path('../lib/cevennes.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'https://github.com/jmettraux/cevennes'
  s.license = 'MIT'
  s.summary = 'CSV diff library'

  s.description = %{
Diffs CSVs by lines, focusing on a single ID
  }.strip

  s.metadata = {
    'changelog_uri' => s.homepage + '/blob/master/CHANGELOG.md',
    'documentation_uri' => s.homepage,
    'bug_tracker_uri' => s.homepage + '/issues',
    #'mailing_list_uri' => 'https://groups.google.com/forum/#!forum/floraison',
    'homepage_uri' =>  s.homepage,
    'source_code_uri' => s.homepage,
    #'wiki_uri' => s.homepage + '/wiki',
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'README.{md,txt}',
    'CHANGELOG.{md,txt}', 'CREDITS.{md,txt}', 'LICENSE.{md,txt}',
    'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    "#{s.name}.gemspec",
  ]

  #s.add_runtime_dependency 'tzinfo'
  #s.add_runtime_dependency 'raabro', '~> 1.1'

  s.add_development_dependency 'rspec', '~> 3.7'

  s.require_path = 'lib'
end

