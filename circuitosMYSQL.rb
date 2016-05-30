require 'rubygems'
require 'mysql'

begin
  db = Mysql.new 'localhost', 'root', 'bela1010', 'telebras'

  rs = db.query('SELECT * FROM circuitos')
    # Read through the result set hash.
  rs.each_hash do |linha|
    puts "#{linha['designacao']}, #{linha['cliente']}, #{linha['status']}" 
  end
  rs.free
rescue Mysql::Error => e
  # Print the error.
  puts "ERROR #{e.errno} (#{e.sqlstate}): #{e.error}"
  puts "Não foi possivel conectar do Banco de Dados"
  # Signal an error.
  exit 1
ensure
  # Close the connection when it is open.
  db.close if db
end

