Gem::Specification.new do |s|
  s.name              = "ost-bin"
  s.version           = "0.0.1"
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

  s.add_dependency "ost"
  s.add_dependency "clap"

  s.add_development_dependency "cutest"
end
