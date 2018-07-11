Gem::Specification.new do |spec|
  spec.name = "em-ftpd"
  spec.version = "0.0.1"
  spec.summary = "An FTP daemon framework"
  spec.description = "Build a custom FTP daemon backed by a datastore of your choice"
  spec.files =  Dir.glob("{bin,examples,lib}/**/**/*") + ["Gemfile", "README.markdown","MIT-LICENSE"]
  spec.executables << "em-ftpd"
  spec.has_rdoc = true
  spec.extra_rdoc_files = %w{README.markdown MIT-LICENSE }
  spec.rdoc_options << '--title' << 'EM::FTPd Documentation' <<
                       '--main'  << 'README.markdown' << '-q'
  spec.authors = ["James Healy"]
  spec.email   = ["jimmy@deefa.com"]
  spec.homepage = "http://github.com/yob/em-ftpd"
  spec.required_ruby_version = ">=2.2"

  spec.add_development_dependency("rake", "~> 10.0")
  spec.add_development_dependency("rspec", "~>3.0")
  spec.add_development_dependency("em-redis")

  spec.add_dependency('eventmachine')
end
