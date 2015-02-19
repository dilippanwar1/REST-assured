module RestAssured
  require "faraday"

  class Response

    def self.perform(app)
      request = app.request
      puts "Request: (#{request.fullpath})"
      if d = Models::Double.where(:fullpath => request.fullpath, :active => true, :verb => request.request_method).first
        return_double app, d
      elsif redirect_url = Models::Redirect.find_redirect_url_for(request.fullpath)
        if d = Models::Double.where(:fullpath => redirect_url, :active => true, :verb => request.request_method).first
          return_double app, d
        else
          if request.get?
            headers = extract_relevant_headers(request.env)
            c = Faraday.new
            response = c.get redirect_url do |req|
              req.headers = headers
            end

            puts("Response: (#{response.status}, #{response.body.class}, #{response.headers})")
            app.headers response.headers
            app.body response.body
            app.status response.status
          end
          #app.redirect redirect_url
        end
      else
        app.status 404
      end
    end

    def self.return_double(app, d)
      request = app.request
      request.body.rewind
      body = request.body.read #without temp variable ':body = > body' is always nil. mistery
      env  = request.env.except('rack.input', 'rack.errors', 'rack.logger')

      d.requests.create!(:rack_env => env.to_json, :body => body, :params => request.params.to_json)

      app.headers d.response_headers
      app.body d.content
      app.status d.status
    end

    def self.extract_relevant_headers(env)
      headers = {}
      env.select { |k, _| k.start_with?("HTTP_") && k != "HTTP_HOST"}
          .each {|k, v| headers[k.sub(/^HTTP_/, '')] = v}
      headers
    end
  end
end
