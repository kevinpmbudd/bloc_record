module BlocRecord
  def self.connect_to(filename, db)
    @database_filename = filename
    @db = db
  end

  def self.database_filename
    @database_filename
  end

  def self.db
    @db
  end
end
