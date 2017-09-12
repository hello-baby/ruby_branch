module RubyBranch
  module API
    class Response

      extend Forwardable

      attr_accessor :response
      def_delegators :@response, :success?, :status, :body

      def initialize(response)
        @response = response
      end

      def json
        JSON.parse(body, symbolize_names: true)
      end

    end
  end
end
