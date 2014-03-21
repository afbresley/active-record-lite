class AttrAccessorObject
  def self.my_attr_accessor(*names)

    names.each do |name|
      define_method(name) do
        instance_variable_get("@#{name}")
      end
    end

    names.each do |name|
      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end

  # def name # =>  GETS
  #   @name
  # end
  #
  # def name=(arg) # => SETS
  #   @name = arg
  # end

end