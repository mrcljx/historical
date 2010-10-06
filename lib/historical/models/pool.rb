module Historical::Models
  module Pool
    # cached classes are stored here

    @@class_pool = {}

    def self.pooled(name)

      return @@class_pool[name] if @@class_pool[name]

      cls = yield

      const_set(name, cls)
      @@class_pool[name] = cls

      cls
    end

    def self.clear!
      @@class_pool.each do |k,v|
        remove_const(k)
      end

      @@class_pool = {}
    end

    def self.pooled_name(specialized_for, parent)
      "#{specialized_for.name.demodulize}#{parent.name.demodulize}"
    end
  end
end