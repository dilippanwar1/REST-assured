module RestAssured
  require "faraday"
  require "uri"

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
          app.redirect redirect_url
        end
      elsif Models::Proxy.exists?
        raise "Only GET is supported for now" unless request.get?

        proxy = Models::Proxy.find(:all).first

        request_url = URI::join(proxy.to, request.fullpath).to_s

        puts "[Proxy request: #{request_url}]"
        response = perform_remote_request(request, request_url)
        puts "[Proxy Response: (#{response.status}, #{response.body.class}, #{response.headers})]"

        return_proxy response, app, proxy
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

    def self.compose_host_url(request)
      host_url = URI("")
      host_url.scheme = request.scheme
      host_url.host = request.host
      host_url.port = request.port
      host_url.to_s
    end

    def self.return_proxy(response, app, proxy)
      host_url = compose_host_url(app.request)

      app.headers response.headers
      app.body rewrite(response.body, proxy.to, host_url)
      app.status response.status
    end

    def self.rewrite(body, from, to)
      body.gsub(/#{from}/, "#{to}")
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
