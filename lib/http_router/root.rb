class HttpRouter
  class Root < Node
    class AlternativeRequestMethods < Array
      attr_accessor :request_method_found
    end
    
    def add_path(path)
      node = path.parts.inject(self) { |node, part| node.add(part) }
      node
    end

    def find(request)
      params = []
      parts = get_parts(request)
      node = find_on_parts(request, parts, params)
      process_response(node, parts, params, request)
    end

    def get_parts(request)
      parts = router.split(request.path_info.dup)
      parts << '' if request.path_info[-1] == ?/
      parts
    end

    private
    def process_response(node, parts, params, request)
      if node && node.value
        if parts.empty?
          Response.matched(node.value, params, request.path_info)
        elsif node.value.route.partially_match?
          rest = '/' << parts.join('/')
          Response.matched(node.value, params, request.path_info[0, request.path_info.size - rest.size], rest)
        else
          nil
        end
      elsif !router.request_methods_specified.empty?
        alternate_methods = (router.request_methods_specified - [request.request_method]).select do |alternate_method|
          test_request = request.dup
          test_request.env['REQUEST_METHOD'] = alternate_method
          node = find_on_parts(test_request, get_parts(request), [])
          node && node.value
        end
        alternate_methods.empty? ? nil : Response.unmatched(405, {"Allow" => alternate_methods.join(", ")})
      else
        nil
      end
    end
  end
end