require_relative '../version'

puts <<-USAGE
TRMNL Preview v#{TRMNLPreview::VERSION}

Usage:

  trmnlp [command] [options]

Commands (-h for command-specific help):

  build     Generate static HTML files
  serve     Start the TRMNL Preview server
  version   Print the version number
USAGE