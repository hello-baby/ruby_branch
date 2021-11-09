module RubyBranch
  module API
    class Request

      def post(resource, body = '')
        response = connection.post do |request|
          request.url resource
          request.headers['Content-Type'] = 'application/json'
          request.body = body unless body.empty?
        end
        Response.new(response)
      end

      def put(resource, body = '')
        response = connection.put do |request|
          request.url resource
          request.headers['Content-Type'] = 'application/json'
          request.body = body unless body.empty?
        end
        Response.new(response)
      end

      def delete(resource)
        response = connection.delete do |request|
          request.url resource
          request.headers['Content-Type'] = 'application/json'
        end
        Response.new(response)
      end

      def connection
        @connection ||=
          Faraday.new(url: BRANCH_API_ENDPOINT) do |connection|
            connection.adapter Faraday.default_adapter
          end
      end

    end
  end
end
