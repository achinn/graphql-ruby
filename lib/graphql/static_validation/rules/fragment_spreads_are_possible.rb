module GraphQL
  module StaticValidation
    class FragmentSpreadsArePossible
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)

        context.visitor[GraphQL::Language::Nodes::InlineFragment] << -> (node, parent) {
          fragment_parent = context.object_types[-2]
          fragment_child = context.object_types.last
          if fragment_child
            validate_fragment_in_scope(fragment_parent, fragment_child, node, context)
          end
        }

        spreads_to_validate = []

        context.visitor[GraphQL::Language::Nodes::FragmentSpread] << -> (node, parent) {
          fragment_parent = context.object_types.last
          spreads_to_validate << [node, fragment_parent]
        }

        context.visitor[GraphQL::Language::Nodes::Document].leave << -> (node, parent) {
          spreads_to_validate.each do |spread_values|
            node, fragment_parent = spread_values
            fragment_child_name = context.fragments[node.name].type
            fragment_child = context.schema.types[fragment_child_name]
            validate_fragment_in_scope(fragment_parent, fragment_child, node, context)
          end
        }
      end

      private

      def validate_fragment_in_scope(parent_type, child_type, node, context)
        intersecting_types = get_possible_types(parent_type, context.schema) & get_possible_types(child_type, context.schema)
        if intersecting_types.none?
          name = node.respond_to?(:name) ? " #{node.name}" : ""
          context.errors << message("Fragment#{name} on #{child_type.name} can't be spread inside #{parent_type.name}", node)
        end
      end

      def get_possible_types(type, schema)
        if type.kind.wraps?
          get_possible_types(type.of_type, schema)
        elsif type.kind.object?
          [type]
        elsif type.kind.resolves?
          schema.possible_types(type)
        else
          []
        end
      end
    end
  end
end
