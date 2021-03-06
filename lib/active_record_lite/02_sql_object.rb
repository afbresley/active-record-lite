require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'
require 'debugger'

class MassObject

  def self.parse_all(results)
    objects = []

    results.each do |result|
      objects << self.new(result)
    end

    objects
  end
end

class SQLObject < MassObject

  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) do
        self.attributes[name.to_sym]
      end
    end

    names.each do |name|
      define_method("#{name}=") do |value|
        self.attributes[name.to_sym] = value
      end
    end
  end

  def self.columns
    col_arr = DBConnection.execute2("SELECT * FROM #{@table_name}")[0]
    col_arr.each do |column|
      my_attr_accessor(column)
    end


  end

  def self.table_name=(table_name = nil)
    @table_name = table_name
  end

  def self.table_name
    # gets the table name
    if @table_name == nil
      @table_name = "#{self}".tableize
    else
      @table_name
    end
  end

  def self.all
    meow = DBConnection.execute(<<-SQL)
    SELECT
      #{self.table_name}.*
    FROM
      #{self.table_name}
      SQL

    parse_all(meow)
  end

  def self.find(id)
    meow = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{self.table_name}.id = ?
    SQL

    self.new(meow.first)
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
     @attributes.values
  end

  def insert
    col_name = self.attributes.keys.join(", ")
    question_marks = (["?"] * self.attributes.values.count).join(', ')
    #the problem is here.... there's something with the ('join')

    meow = DBConnection.execute(<<-SQL, attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_name})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end
  #
  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        raise unknown attribute '#{attr_name}'
      else
        self.send("#{attr_name}=", value)
      end
    end
  end

  def save
    id.nil? ? insert : update
  end

  def update
    #debugger
    update_line = self.class.columns
      .map { |attr| "#{ attr } = ?" }.join(", ")
      #debugger
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{ self.class.table_name }
      SET
        #{ update_line }
      WHERE
        #{ self.class.table_name }.id = ?
    SQL
  end

  # def attribute_values
  #   # ...
  # end
end
