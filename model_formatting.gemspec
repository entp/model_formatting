$LOAD_PATH.unshift 'lib'
require 'model_formatting'

spec = Gem::Specification.new do |s|
  s.name = "model_formatting"
  s.version = "0.6.7"
  s.date = "2014-11-25"
  s.author = "ENTP"
  s.email = "company@entp.com"
  s.homepage = "http://github.com/entp"
  s.platform = Gem::Platform::RUBY
  s.summary = "Automatically format model attributes using redcarpet (markdown) and Tender/Lighthouse extensions."
  # s.files = FileList['[a-zA-Z]*', 'bin/*', 'lib/**/*', 'rails/**/*', 'test/**/*']
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]
  s.add_dependency("redcarpet", "~>2.2")
  s.add_dependency("actionpack", "~>3.2")
  s.add_dependency("activerecord", "~>3.2")
  s.add_dependency("activesupport", "~>3.2")
  s.add_dependency("tidy_ffi", "~>0.1.2")
  s.add_development_dependency("jeremymcanally-context", "~>0.5.5")
  s.add_development_dependency("jeremymcanally-matchy", "~>0.1.0")
end
