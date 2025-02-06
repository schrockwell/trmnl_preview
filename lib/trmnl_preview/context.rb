require 'erb'
require 'fileutils'
require 'filewatcher'
require 'json'
require 'liquid'
require 'open-uri'
require 'toml-rb'
require 'dotenv'

require_relative 'custom_filters'

module TRMNLPreview
  class Context
    attr_reader :strategy, :temp_dir, :live_render
    
    def initialize(root, opts = {})
      @root = root
      @config = load_config
      @secrets = load_secrets
      replace_tokens! if @secrets
      @user_views_dir = File.join(root, 'views')
      @temp_dir = File.join(root, 'tmp')
      @data_json_path = File.join(@temp_dir, 'data.json')

      unless File.exist?(File.join(root, 'config.toml'))
        raise "No config.toml found in #{root}"
      end
    
      unless Dir.exist?(@user_views_dir)
        raise "No views found at #{@user_views_dir}"
      end

      @strategy = @config['strategy']
      @url = @config['url']
      @polling_headers = @config['polling_headers'] || {}
      @live_render = @config['live_render'] != false
      @user_filters = @config['custom_filters'] || []

      unless ['polling', 'webhook', 'static'].include?(@strategy)
        raise "Invalid strategy: #{@strategy} (must be 'polling', 'webhook', or 'static')"
      end
      
      FileUtils.mkdir_p(@temp_dir)

      @liquid_environment = Liquid::Environment.build do |env|
        env.register_filter(CustomFilters)

        @user_filters.each do |module_name, relative_path|
          require File.join(root, relative_path)
          env.register_filter(Object.const_get(module_name))
        end
      end

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
      case @strategy
      when 'polling'
        fetch_data_from_url
      when 'static'
        load_static_data
      else
        raise "Unsupported strategy: #{@strategy}"
      end

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
      page_erb_template = File.read(File.join(__dir__, '..', '..', 'web', 'views', 'render_html.erb'))
      
      ERB.new(page_erb_template).result(ERBBinding.new(view).get_binding do
        render_template(view)
      end)
    end

    private 

    def load_config
      config_file = File.join(@root, 'config.toml')
      raise "Configuration file not found: #{config_file}" unless File.exist?(config_file)
      
      TomlRB.load_file(config_file)
    end

    def load_secrets
      env_file = File.join(@root, '.env')
      return nil unless File.exist?(env_file)
      
      # Load the raw contents to check for hyphens before parsing
      env_contents = File.read(env_file)
      env_contents.each_line do |line|
        line = line.strip
        next if line.empty? || line.start_with?('#')
        
        if line.match?(/^[A-Za-z0-9-]+\s*=/)
          key = line.split('=', 2).first.strip
          if key.include?('-')
            raise "Invalid environment variable '#{key}' in #{env_file}\n" \
                  "Environment variables should use underscores (_) instead of hyphens (-)\n" \
                  "Example: Change '#{key}' to '#{key.gsub('-', '_')}'"
          end
        end
      end
      
      Dotenv.load(env_file)
      ENV.to_h
    end

    def replace_tokens!
      replace_tokens_in_hash(@config, @secrets)
    end

    def replace_tokens_in_hash(hash, secrets)
      hash.each do |key, value|
        case value
        when String
          hash[key] = replace_token(value, secrets)
        when Hash
          replace_tokens_in_hash(value, secrets)
        when Array
          value.each_with_index do |item, index|
            case item
            when String
              value[index] = replace_token(item, secrets)
            when Hash
              replace_tokens_in_hash(item, secrets)
            end
          end
        end
      end
    end

    def replace_token(value, secrets)
      return value unless value.match?(/\{[^}]+\}/)
      
      # Replace all occurrences of {VARIABLE} in the string
      value.gsub(/\{([^}]+)\}/) do |match|
        token = $1  # Capture the variable name from inside the brackets
        secret_key = find_secret_key(token, secrets)
        
        if secret_key
          secrets[secret_key]
        else
          env_path = File.join(@root, '.env')
          raise "Token '#{token}' not found in #{env_path}"
        end
      end
    end

    def find_secret_key(token, secrets)
      # Case-insensitive search for the key
      secrets.keys.find { |key| key.to_s.downcase == token.downcase }
    end

    def fetch_data_from_url
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
    end

    def load_static_data
      static_file = File.join(@root, 'sample.json')
      unless File.exist?(static_file)
        raise "Static data file not found: #{static_file}"
      end

      payload = File.read(static_file)
      File.write(@data_json_path, payload)
      puts "Loaded static data from #{static_file}"
    end

    class ERBBinding
      def initialize(view) = @view = view
      def get_binding = binding
    end
  end
end