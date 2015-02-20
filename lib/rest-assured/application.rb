require 'sinatra/base'
require 'haml'
require 'sinatra/flash'
require 'sinatra/partials'
require 'rest-assured/config'
require 'rest-assured/models/double'
require 'rest-assured/models/redirect'
require 'rest-assured/models/request'
require 'rest-assured/models/proxy'
require 'rest-assured/routes/double'
require 'rest-assured/routes/redirect'
require 'rest-assured/routes/response'
require 'rest-assured/routes/proxy'

module RestAssured
  class Application < Sinatra::Base

    include Config

    enable :method_override

    enable :sessions
    register Sinatra::Flash

    set :public_folder, File.expand_path('../../../public', __FILE__)
    set :views, File.expand_path('../../../views', __FILE__)
    set :haml, :format => :html5

    helpers Sinatra::Partials

    helpers do
      def browser?
        request.user_agent =~ /Safari|Firefox|Opera|MSIE|Chrome/
      end
    end

    include DoubleRoutes
    include RedirectRoutes
    include ProxyRoutes

    %w{get post put delete}.each do |verb|
      send verb, /.*/ do
        Response.perform(self)
      end
    end
  end
end

