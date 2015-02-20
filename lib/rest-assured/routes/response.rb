module RestAssured
  require "faraday"

  class Response

    def self.perform(app)
      request = app.request
      puts "Request: (#{request.fullpath})"

      if d = double_for_fullpath(request.fullpath, request.request_method)
        return_double app, d
      elsif redirect_url = Models::Redirect.find_redirect_url_for(request.fullpath)
        if d = double_for_fullpath(redirect_url, request.request_method)
          return_double app, d
        else
          raise "Only GET is supported for now" unless request.get?

          response = perform_remote_request(request, redirect_url)
          puts("Response: (#{response.status}, #{response.body.class}, #{response.headers})")
          return_proxy response, app

          #app.redirect redirect_url
        end
      else
        app.status 404
      end
    end


    def self.perform_remote_request(request, redirect_url)
      headers = extract_relevant_headers(request.env)
      c = Faraday.new
      c.get redirect_url do |req|
        req.headers = headers
      end
    end

    def self.return_proxy(response, app)
      app.headers response.headers
      app.body response.body
      app.status response.status
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

    def self.double_for_fullpath(fullpath, request_method)
      doubles = Models::Double.where(:active => true, :verb => request_method)
      doubles.select {|d| fullpath =~ /#{d.fullpath}/}.first
    end
  end
end
