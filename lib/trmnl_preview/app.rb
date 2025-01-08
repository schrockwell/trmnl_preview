
require 'faye/websocket'
require 'sinatra'
require 'sinatra/base'

require_relative 'context'
require_relative 'screen_generator'

module TRMNLPreview
  class App < Sinatra::Base
    # Sinatra settings
    set :views, File.join(File.dirname(__FILE__), '..', '..', 'web', 'views')
    set :public_folder, File.join(File.dirname(__FILE__), '..', '..', 'web', 'public')
    
    def initialize(*args)
      super

      begin
        @context = Context.new(settings.user_dir)
      rescue StandardError => e
        puts e.message
        exit 1
      end

      @context.poll_data if @context.strategy == 'polling'

      @live_reload_clients = []
      @context.on_view_change do |view|
        @live_reload_clients.each do |ws|
          ws.send('reload')
        end
      end
    end

    post '/webhook' do
      @context.set_data(request.body.read)
      "OK"
    end
    
    get '/' do
      redirect '/full'
    end

    get '/live_reload' do
      ws = Faye::WebSocket.new(request.env)

      ws.on(:open) do |event|
        @live_reload_clients << ws
      end
  
      ws.on(:close) do |event|
        @live_reload_clients.delete(ws)
      end
  
      ws.rack_response
    end

    get '/poll' do
      @context.poll_data
      redirect back
    end
    
    VIEWS.each do |view|
      get "/#{view}" do
        @view = view
        @live_reload = @context.live_render
        erb :index
      end

      get "/render/#{view}.html" do
        @view = view
        erb :render_html do
          @context.render_template(view)
        end
      end

      get "/render/#{view}.bmp" do
        @view = view
        html = @context.render_full_page(view)
        generator = ScreenGenerator.new(html, image: true)
        img_path = generator.process
        send_file img_path, type: 'image/png', disposition: 'inline'
      end
    end
  end
end