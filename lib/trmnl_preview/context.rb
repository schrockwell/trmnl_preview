require 'erb'
require 'fileutils'
require 'filewatcher'
require 'json'
require 'liquid'
require 'open-uri'
require 'toml-rb'

require_relative 'liquid_filters'

module TRMNLPreview
  class Context
    attr_reader :strategy, :temp_dir, :live_render
    
    def initialize(root)
      config_path = File.join(root, 'config.toml')
      @user_views_dir = File.join(root, 'views')
      @temp_dir = File.join(root, 'tmp')
      @data_json_path = File.join(@temp_dir, 'data.json')
    
      @liquid_environment = Liquid::Environment.build do |env|
        env.register_filter(LiquidFilters)
      end

      unless File.exist?(config_path)
        raise "No config.toml found in #{root}"
      end
    
      unless Dir.exist?(@user_views_dir)
        raise "No views found at #{@user_views_dir}"
      end

      config = TomlRB.load_file(config_path)
      @strategy = config['strategy']
      @url = config['url']
      @polling_headers = config['polling_headers'] || {}
      @live_render = config['live_render'] != false

      unless ['polling', 'webhook'].include?(@strategy)
        raise "Invalid strategy: #{strategy} (must be 'polling' or 'webhook')"
      end

      FileUtils.mkdir_p(@temp_dir)

      start_filewatcher_thread if @live_render
    end

    def start_filewatcher_thread
      Thread.new do
        loop do
          begin
            Filewatcher.new(@user_views_dir).watch do |changes|
              views = changes.map { |path, _change| File.basename(path, '.liquid') }
              views.each do |view|
                @view_change_callback.call(view) if @view_change_callback
              end
            end
          rescue => e
            puts "Error during live render: #{e}"
          end
        end
      end
    end

    def on_view_change(&block)
      @view_change_callback = block
    end

    def user_data
      data = JSON.parse(File.read(@data_json_path))
      data = { data: data } if data.is_a?(Array) # per TRMNL docs, bare array is wrapped in 'data' key
      data
    end

    def poll_data
      if @url.nil?
        raise "URL is required for polling strategy"
      end

      print "Fetching #{@url}... "

      if @url.match?(/^https?:\/\//)
        payload = URI.open(@url, @polling_headers).read
      else
        payload = File.read(@url)
      end

      File.write(@data_json_path, payload)
      puts "got #{payload.size} bytes"

      user_data
    end

    def set_data(payload)
      File.write(@data_json_path, payload)
    end

    def view_path(view)
      File.join(@user_views_dir, "#{view}.liquid")
    end

    def render_template(view)
        path = view_path(view)
        unless File.exist?(path)
          return "Missing plugin template: views/#{view}.liquid"
        end

        user_template = Liquid::Template.parse(File.read(path), environment: @liquid_environment)
        user_template.render(user_data)
    rescue StandardError => e
      e.message
    end

    def render_full_page(view)
      page_erb_template = File.read(File.join(__dir__, '..', '..', 'web', 'views', 'render_view.erb'))
      
      ERB.new(page_erb_template).result(ERBBinding.new(view).get_binding do
        render_template(view)
      end)
    end

    private 

    class ERBBinding
      def initialize(view) = @view = view
      def get_binding = binding
    end
  end
end