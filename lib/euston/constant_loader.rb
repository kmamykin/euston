module Euston

class ConstantLoader
  include Hollywood

  def load string
    namespace = Object
    found = true

    string.split('::').each do |segment|
      if found && namespace.const_defined?(segment)
        namespace = namespace.const_get segment.to_sym
      else
        found = false
      end
    end

    if found
      callback :hit, namespace
    else
      callback :miss, string
    end
  end
end

end
