module Arel
  module Nodes
    class Contained < Arel::Nodes::Binary
      def operator
        "<@"
      end
    end

    class Containz < Arel::Nodes::Binary
      def operator
        "@>"
      end
    end

    class Overlapz < Arel::Nodes::Binary
      def operator
        "&&"
      end
    end
  end

  module Predications
    def contained(other)
      Nodes::Contained.new(self, quoted_node(other))
    end

    def contains(other)
      Nodes::Containz.new(self, quoted_node(other))
    end

    def overlaps(other)
      Nodes::Overlapz.new(self, quoted_node(other))
    end
  end

  module Visitors
    class PostgreSQL < Arel::Visitors::ToSql
      private

      def visit_Arel_Nodes_Contained(o, collector)
        infix_value(o, collector, " <@ ")
      end

      def visit_Arel_Nodes_Containz(o, collector)
        infix_value(o, collector, " @> ")
      end

      def visit_Arel_Nodes_Overlapz(o, collector)
        infix_value(o, collector, " && ")
      end
    end
  end
end
