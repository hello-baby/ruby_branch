module RubyBranch
  module API
    module Resources
      class Link

        LINK_LENGTH_LIMIT = 2000

        def create_safely(analytics: {}, data: {}, settings: {})
          build(analytics: analytics, data: data, settings: settings)
        rescue Errors::LinkLengthExceedError
          create(analytics: analytics, data: data, settings: settings)
        end

        def create(analytics: {}, data: {}, settings: {})
          request_body = build_request_body(analytics, settings, data)
          response = do_create_request(request_body)

          return response.json[:url] if response.success?

          error_attrs = { status: response.status, body: response.body }
          if defined?(Bugsnag) && defined?(Rails)
            Bugsnag.notify(Errors::ApiResponseError.new, error_attrs) if Rails.env.production?
          end

          RubyBranch.config.link_to_homepage if RubyBranch.config.link_to_homepage
        end

        def build(analytics: {}, data: {}, settings: {})
          params = {}
          params.merge!(prepare_analytics(analytics))
          params.merge!(prepare_settings(settings))
          params.merge!(data)

          link = Addressable::URI.new(
            scheme: 'https',
            host: RubyBranch.config.branch_domain,
            path: "/a/#{RubyBranch.config.api_key}",
            query: params.to_query
          ).to_s
          check_for_link_length_limit(link)
          link
        end

        private

        def do_create_request(request_body)
          request = Request.new
          request.post('v1/url', request_body.to_json)
        end

        def build_request_body(analytics, settings, data)
          body = { branch_key: RubyBranch.config.api_key }
          body.merge! prepare_analytics(analytics)
          body.merge! prepare_settings(settings)
          body.merge! prepare_data(data)
        end

        def prepare_data(data)
          { data: data }
        end

        def prepare_analytics(analytics)
          allowed_params = %i[channel feature campaign stage tags]
          analytics.reject { |k, v| !allowed_params.include?(k) || v.nil? }
        end

        def prepare_settings(settings)
          allowed_params = %i[alias type duration identity]
          settings.reject { |k, v| !allowed_params.include?(k) || v.nil? }
        end

        def check_for_link_length_limit(link)
          raise Errors::LinkLengthExceedError if link.size > LINK_LENGTH_LIMIT
        end

      end
    end
  end
end
