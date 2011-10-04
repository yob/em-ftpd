Gem::Specification.new do |spec|
  spec.name = "em-ftpd"
  spec.version = "0.0.1"
  spec.summary = "An FTP daemon framework"
  spec.description = "Build a custom FTP daemon backed by a datastore of your choice"
  spec.files =  Dir.glob("{examples,lib}/**/**/*") + ["Gemfile", "-README.markdown","MIT-LICENSE"]
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README.rdoc MIT-LICENSE }
  spec.rdoc_options << '--title' << 'EM::FTPd Documentation' <<
                       '--main'  << 'README.rdoc' << '-q'
  spec.authors = ["James Healy"]
  spec.email   = ["jimmy@deefa.com"]
  spec.homepage = "http://github.com/yob/em-ftpd"
  spec.required_ruby_version = ">=1.9.2"

  spec.add_development_dependency("rspec", "~>2.6")
  spec.add_development_dependency("em-redis")
  spec.add_development_dependency("guard")
  spec.add_development_dependency("guard-process")
  spec.add_development_dependency("guard-bundler")

  spec.add_dependency('em-synchrony')
end
