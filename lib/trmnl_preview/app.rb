
require 'faye/websocket'
require 'sinatra'
require 'sinatra/base'

require_relative 'context'

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

      @live_render_clients = VIEWS.each_with_object({}) { |view, hash| hash[view] = [] }
      @context.on_view_change do |view|
        @live_render_clients[view].each do |ws|
          ws.send(@context.render_template(view))
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

    get '/live_render/:view' do
      ws = Faye::WebSocket.new(request.env)
      view = params['view']

      ws.on(:open) do |event|
        @live_render_clients[view] << ws
      end
  
      ws.on(:close) do |event|
        @live_render_clients[view].delete(ws)
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
        erb :index
      end

      get "/render/#{view}" do
        @view = view
        @live_render = @context.live_render
        erb :render_view do
          @context.render_template(view)
        end
      end
    end
  end
end