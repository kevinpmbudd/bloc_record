module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def take
      return unless self.any?
      self.first.take_one
    end

    def where(*args)
      return unless self.any?
      self.first.class.where(args)
    end

    def not(*args)
      return unless self.any?
      self.first.class.all - self.first.class.where(args)
    end
  end
end
