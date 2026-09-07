# frozen_string_literal: true

require_relative 'lib/trmnlp/version'

Gem::Specification.new do |spec|
  spec.name = 'trmnl_preview'
  spec.version = TRMNLP::VERSION
  spec.authors = ['Rockwell Schrock']
  spec.email = ['rockwell@schrock.me']

  spec.summary = 'Local web server to preview TRMNL plugins'
  spec.description = 'Automatically rebuild and preview TRNML plugins in multiple views'
  spec.homepage = 'https://github.com/usetrmnl/trmnlp'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 4.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/usetrmnl/trmnlp'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    files = [
      'bin/**/*',
      'db/**/*',
      'lib/**/*',
      'web/**/*',
      'CHANGELOG.md',
      'LICENSE.txt',
      'README.md',
      'trmnl_preview.gemspec'
    ].flat_map { |glob| Dir[glob] }

    # FNM_DOTMATCH so the glob descends into the templates' hidden directories
    # (e.g. .github/) — a plain Dir[] skips them and drops the file from the gem.
    files + Dir.glob('templates/**/{*,.*}', File::FNM_DOTMATCH)
  end
  spec.bindir = 'bin'
  spec.executables = ['trmnlp']
  spec.require_paths = ['lib']

  # Web server
  spec.add_dependency 'puma', '~> 8.0'
  spec.add_dependency 'rackup', '~> 2.2'
  spec.add_dependency 'sinatra', '~> 4.1'

  # HTML rendering
  spec.add_dependency 'activesupport', '~> 8.0'
  spec.add_dependency 'trmnl-liquid', '~> 0.8.2'

  # PNG rendering
  # spec.add_dependency 'puppeteer-ruby', '~> 0.45.6'
  spec.add_dependency 'mini_magick', '~> 5.3'
  spec.add_dependency 'selenium-webdriver', '~> 4.44'

  # OAuth2 (local plugin preview auth flow)
  spec.add_dependency 'oauth2', '~> 2.0'

  # Utilities
  spec.add_dependency 'cgi', '~> 0.5'
  spec.add_dependency 'faraday', '~> 2.1'
  spec.add_dependency 'faraday-multipart', '~> 1.1'
  spec.add_dependency 'filewatcher', '~> 3.0'
  spec.add_dependency 'oj', '~> 3.17'
  spec.add_dependency 'rexml', '~> 3.4'
  spec.add_dependency 'rubyzip', '~> 3.3'
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'tzinfo-data', '~> 1.2025'
  spec.add_dependency 'xdg', '~> 10.2'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
