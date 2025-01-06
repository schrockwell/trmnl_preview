require 'optionparser'

require_relative '../context'

OptionParser.new do |opts|
  opts.banner = "Usage: trmnlp build [directory]"
end.parse!

root = ARGV[1] || Dir.pwd
begin
  context = TRMNLPreview::Context.new(root)
rescue StandardError => e
  puts e.message
  exit 1
end

context.poll_data

TRMNLPreview::VIEWS.each do |view|
  output_path = File.join(context.temp_dir, "#{view}.html")
  puts "Creating #{output_path}..."
  File.write(output_path, context.render_full_page(view))
end

puts "Done!"