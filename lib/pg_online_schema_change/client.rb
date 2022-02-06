require "pg"

module PgOnlineSchemaChange
  class Client
    attr_accessor :alter_statement, :schema, :dbname, :host, :username, :port, :password, :connection, :table, :drop,
                  :kill_backends, :wait_time_for_lock

    def initialize(options)
      @alter_statement = options.alter_statement
      @schema = options.schema
      @dbname = options.dbname
      @host = options.host
      @username = options.username
      @port = options.port
      @password = options.password
      @drop = options.drop
      @kill_backends = options.kill_backends
      @wait_time_for_lock = options.wait_time_for_lock

      @connection = PG.connect(
        dbname: @dbname,
        host: @host,
        user: @username,
        password: @password,
        port: @port,
      )

      raise Error, "Not a valid ALTER statement: #{@alter_statement}" unless Query.alter_statement?(@alter_statement)

      unless Query.same_table?(@alter_statement)
        raise Error "All statements should belong to the same table: #{@alter_statement}"
      end

      @table = Query.table(@alter_statement)

      PgOnlineSchemaChange.logger.debug("Connection established")
    end
  end
end
