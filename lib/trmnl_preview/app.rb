
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
    end

    post '/webhook' do
      @context.set_data(request.body.read)
      "OK"
    end
    
    get '/' do
      redirect '/full'
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
        erb :render_view do
          @context.render_template(view)
        end
      end
    end
  end
end