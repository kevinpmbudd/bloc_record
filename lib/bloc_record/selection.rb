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
    unless id.is_a? Integer && id >= 0
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
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
