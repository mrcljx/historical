module Historical::Models
  # @private
  # cached classes are stored here
  module Pool
    @@class_pool = {}
    mattr_accessor :class_pool

    # Gets a class from the pool or sets it if the class couldn't be found.
    def self.pooled(name)
      class_pool[name] ||= begin
        yield.tap do |cls|
          const_set(name, cls)
        end
      end
    end

    # Removes all stored classes from the pool
    def self.clear!
      class_pool.each do |k,v|
        remove_const(k)
      end

      self.class_pool = {}
    end

    # Generate unique classnames within the pool.
    def self.pooled_name(specialized_for, parent)
      raise "specialized_for must be present" unless specialized_for
      raise "parent must be a Class" unless parent.is_a? Class
      
      case specialized_for
      when Class
        "#{specialized_for.name.demodulize}#{parent.name.demodulize}"
      else
        "#{specialized_for}#{parent.name.demodulize}"
      end
    end
  end
end