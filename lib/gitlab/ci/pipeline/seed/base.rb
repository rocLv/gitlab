module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Base
          def attributes
            raise NotImplementedError
          end

          def excluded?
            raise NotImplementedError
          end
        end
      end
    end
  end
end
