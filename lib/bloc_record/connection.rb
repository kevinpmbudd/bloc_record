require 'sqlite3'
require 'pg'

module Connection
  def connection
    if BlocRecord.db == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    else
      @connection ||= PG::Connection.open(:dbname => BlocRecord.database_filename)
    end
  end
end
