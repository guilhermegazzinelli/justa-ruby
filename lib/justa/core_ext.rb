class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  def present?
    !blank?
  end
end

class String
  def to_camel method = nil
    case method
    when nil
      return self.split(/_/).map(&:capitalize).join if method == nil
    when :lower
      return self.split(/_/)[0] + self.split(/_/)[1..-1].map(&:capitalize).join if method == :lower
    end
  end

  def to_snake
    self.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
  end
end
