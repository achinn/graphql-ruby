module GraphQL
  module Execution
    # Boolean checks for how an AST node's directives should
    # influence its execution
    module DirectiveChecks
      SKIP = "skip"
      INCLUDE = "include"
      DEFER = "defer"
      STREAM = "stream"

      module_function

      # @return [Boolean] Should this AST node be deferred?
      def defer?(ast_node)
        ast_node.directives.any? { |dir| dir.name == DEFER }
      end

      # @return [Boolean] Should this AST node be streamed?
      def stream?(ast_node)
        ast_node.directives.any? { |dir| dir.name == STREAM }
      end

      # This covers `@include(if:)` & `@skip(if:)`
      # @return [Boolean] Should this AST node be skipped altogether?
      def skip?(irep_node, query)
        irep_node.directives.each do |directive_node|
          if directive_node.name == SKIP || directive_node.name == INCLUDE
            directive_defn = directive_node.definition
            args = query.arguments_for(directive_node)
            if !directive_defn.include?(args)
              return true
            end
          end
        end
        false
      end
    end
  end
end
