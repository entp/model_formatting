require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = "model_formatting"
  s.version = "0.1.0"
  s.author = "ENTP"
  s.email = "company@entp.com"
  s.homepage = "http://github.com/entp"
  s.platform = Gem::Platform::RUBY
  s.summary = "Automatically format model attributes using rdiscount and Tender/Lighthouse extensions."
  s.files = FileList['[a-zA-Z]*', 'lib/**/*', 'rails/**/*', 'test/**/*']
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]
  s.add_dependency("actionpack", "~>2.2.3")
  s.add_dependency("activerecord", "~>2.2.3")
  s.add_dependency("activesupport", "~>2.2.3")
  s.add_dependency("rdiscount", "~>1.2.11")
  s.add_dependency("tidy", "~>1.1.2")
  s.add_development_dependency("jeremymcanally-context", "~>0.5.5")
  s.add_development_dependency("jeremymcanally-matchy", "~>0.1.0")
end


desc 'Build the gem.'
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

