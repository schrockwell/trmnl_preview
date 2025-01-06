# frozen_string_literal: true

require_relative "lib/trmnl_preview/version"

Gem::Specification.new do |spec|
  spec.name = "trmnl_preview"
  spec.version = TRMNLPreview::VERSION
  spec.authors = ["Rockwell Schrock"]
  spec.email = ["rockwell@schrock.me"]

  spec.summary = "Local web server to preview TRMNL plugins"
  spec.description = "Automatically rebuild and preview TRNML plugins in multiple views"
  spec.homepage = "https://github.com/schrockwell/trmnl_preview"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/schrockwell/trmnl_preview"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile Dockerfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = ["trmnlp"]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "sinatra", "~> 4.1"
  spec.add_dependency "rackup", "~> 2.2"
  spec.add_dependency "puma", "~> 6.5"
  spec.add_dependency "liquid", "~> 5.6"
  spec.add_dependency "toml-rb", "~> 3.0"
  spec.add_dependency "filewatcher", "~> 2.1"
  spec.add_dependency "faye-websocket", "~> 0.11.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
