require File.expand_path("lib/ost-bin/version", File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name              = "ost-bin"
  s.version           = Ost::Bin::VERSION
  s.summary           = "ost(1)"
  s.authors           = ["Damian Janowski"]
  s.email             = ["damian.janowski@gmail.com"]
  s.homepage          = "https://github.com/djanowski/ost-bin"

  s.files = Dir[
    "*.gemspec",
    "CHANGELOG*",
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "lib/**/*.rb",
    "test/*.*"
  ]

  s.executables << "ost"

  s.add_dependency "ost"
  s.add_dependency "clap"

  s.add_development_dependency "cutest"
end
