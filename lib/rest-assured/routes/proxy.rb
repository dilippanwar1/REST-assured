module RestAssured
  module ProxyRoutes
    def self.included(router)
      router.get '/proxies' do
        @proxies = Models::Proxy.find(:all)
        haml :'proxies/index'
      end

      router.get '/proxies/new' do
        @proxy = Models::Proxy.new
        haml :'proxies/new'
      end

      router.post /^\/proxies(.json)?$/ do |needs_json|
        #TODO: better error handling and move verification to proxy
        if Models::Proxy.exists?
          status 400
          body "Only one proxy can exist"
          return
        end

        @proxy = Models::Proxy.create(params['proxy'] || { :to => params['to'] })

        if needs_json
          if @proxy.errors.present?
            status 400
            body @proxy.errors.full_messages.join("\n")
          end
        else
          if @proxy.errors.blank?
            flash[:notice] = "Proxy created"
            redirect '/proxies'
          else
            flash.now[:error] = "Crumps! " + @proxy.errors.full_messages.join("; ")
            haml :'proxies/new'
          end
        end
      end

      router.get %r{/proxies/(\d+)/edit} do |id|
        @proxy = Models::Proxy.find(id)
        haml :'proxies/edit'
      end

      router.put %r{/proxies/(\d+)} do |id|
        @proxy = Models::Proxy.find(id)

        @proxy.update_attributes(params['proxy'])

        if @proxy.save
          flash[:notice] = 'Proxy updated'
          redirect '/proxies'
        else
          flash[:error] = 'Crumps! ' + @proxy.errors.full_messages.join("\n")
          haml :'proxies/edit'
        end
      end

      router.delete %r{/proxies/(\d+)} do |id|
        if Models::Proxy.destroy(id)
          flash[:notice] = 'Proxy deleted'
          redirect '/proxies'
        end
      end

      router.delete '/proxies/all' do
        status Models::Proxy.delete_all ? 200 : 500
      end
    end
  end
end
