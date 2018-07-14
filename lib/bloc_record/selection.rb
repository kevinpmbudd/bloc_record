require 'sqlite3'

module Selection
  def find(*ids)
    ids.each do |id|
      unless id.is_a? Integer && id >= 0
        raise ArgumentError.new('Invalid ID.')
      end
    end

    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    unless id.is_a?(Integer) && id >= 1
      raise ArgumentError.new('Invalid ID.')
    end

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
    SQL
    init_object_from_row(row)
  end

  def find_by(attribute, value)
    unless columns.include?(attribute)
      raise ArgumentError.new('Invalid attribute.')
    end

    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def first
    get_one("ASC")
  end

  def last
    get_one("DESC")
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def find_each(start=0, batch_size=nil)
    if batch_size
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        LIMIT #{batch_size}
        OFFSET #{start};
      SQL

      rows_to_array(rows).each do |each|
        yield
      end
    else
      all.each do |each|
        yield
      end
    end
  end

  def find_in_batches(start=0, batch_size=nil)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      LIMIT #{batch_size}
      OFFSET #{start};
    SQL

    yield rows_to_array(rows)
  end

  def method_missing(m, *args, &block)
    attribute = m.to_s.sub('find_by_', '').to_sym
    find_by(attribute, *args[0])
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key,value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      order = []
      args.each_with_index do |arg, index|
        case arg
        when String
          if arg.downcase.include?('asc')
            order << arg.downcase.gsub(/asc/, 'order by asc')
          elsif arg.downcase.include?('desc')
            order << arg.downcase.gsub(/desc/, 'order by desc')
          else
            order << arg
          end
        when Hash
          order << arg.keys.first.to_s
          value = arg.values.first.to_s.downcase
          if value.include?('asc')
            order << value.gsub(/asc/, 'order by asc')
          elsif value.include?('desc')
            order << value.gsub(/desc/, 'order by desc')
          else
            order << value
          end
        when Symbol
          order << arg.to_s
        end
      end
      order = order.join(', ')
    else
      order = args.first.to_s
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL

    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{BlocRecord::Utility.underscore(args.keys.first)} ON #{BlocRecord::Utility.underscore(args.keys.first)}.#{table}_id = #{table}.id
          INNER JOIN #{BlocRecord::Utility.underscore(args.values.first)} ON #{BlocRecord::Utility.underscore(args.values.first)}.#{BlocRecord::Utility.underscore(args.keys.first)}_id = #{BlocRecord::Utility.underscore(args.keys.first)}.id
        SQL
      end
    end

    rows_to_array(rows)
  end

  private

  def get_one(order)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id #{order} LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end
end
