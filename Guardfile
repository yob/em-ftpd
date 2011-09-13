guard 'bundler' do
  watch('Gemfile')
end

%w(redis).each do |name|
  guard 'process', :name => "example-#{name}", :command => "ruby examples/#{name}.rb", :stop_signal => 'KILL' do
    watch('Gemfile')
    watch(/^lib.*\.rb/)
    watch(%r{^examples/#{Regexp.escape(name)}\.rb})
  end
end

guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec/" }
end
