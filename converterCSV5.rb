# DATA: 05/04/2016
# PROGRAMADOR: Wagner Röse
# OBJETIVO: Criar um script para importar os dados de arquivo csv
#		 atualizando o BD contendo informação da situação das implantações de cliente da
#		regional de Porto Alegre.
# Importa arquivo CSV, Parametro: PATH=/caminho/completo/para/o/arquivo.csv"

require 'csv'
require 'date'
require 'mysql2'
#require 'time'

#=====================================
# valida data segundo formato mm/dd/yyyy
def valid_date?( str, format="%Y/%m/%d" )
  Date.strptime(str,format) rescue false
end
#======================================
def criaconsulta (dados)
  colunas = dados.keys
  valores = dados.values
  saida = ""
  consulta = "\nINSERT INTO circuitos ("
  colunas.each_with_index { |nomeCampo,indice|
    case indice
    when 0
      consulta << "#{nomeCampo}"
    else
      consulta << ",#{nomeCampo}"
    end
  }
  consulta += ") VALUES ("
  valores.each_with_index { |valor, indice| # imprime valores numericos
    case indice
    when 0
      consulta << "\'#{valor}\'"
    when 5..6,17 
      #      consulta << ","
      consulta<< ",#{valor}"
    else
      consulta<< ",\'#{valor}\'"
    end
  } 
  consulta<< ");"

  return consulta.gsub(/ nil|N\/A|\[|\]/,"").gsub(/\"/,"\'") # filtra caracteres especiais
end

csv_Circuito = "./saidaCircuito.csv"

puts "Verificando a existência do arquivo..."

unless File::exists?(csv_Circuito) # abre arquivo csv de entrada para leitura
  abort("Arquivo CSV contendo Circuitos nao encontrado, verifique se esta correto e tente novamente.")
end
puts "Arquivo de Entrada encontrado!"
puts "Executando importacao, aguarde..."

# conectando com banco de dados
dbCircuito = Mysql2::Client.new(:host => "localhost", 
                                :username => "root", 
                                :password => "bela1010", 
                                :database => 'telebras')

dbCircuito.query("DROP TABLE circuitos_ant") #apaga tabela circuitos_ant
dbCircuito.query("CREATE TABLE circuitos_ant SELECT * FROM circuitos") # copia tabela circuitos para circuitos_ant
dbCircuito.query("DELETE FROM circuitos") #apaga todos os registros da tabela circuito
conta = 0
contaCircuito = 0 
# le arquivo csv de entrada
CSV.foreach("#{csv_Circuito}", encoding:'utf-8', col_sep: ';', row_sep: :auto, headers:true) do |linha|
  designacao = linha['designacao']
  cliente = linha['cliente']
  dado = linha.to_hash
  consulta = criaconsulta(dado)
  #  puts "\n#{consulta}\n" # >>> checagem:
  dbCircuito.query("#{consulta}") #adiciona ao banco de dados
end
# relaciona circuitos com alteração status
consulta = "SELECT tb1.designacao, tb1.cliente, tb1.status, tb2.status "
consulta += "FROM circuitos as tb1" 
consulta += "INNER JOIN circuitos_ant as tb2 ON tb1.designacao = tb2.designacao "
consulta += "WHERE tb1.status <> tb2.status"

# relaciona circuitos com alteração evento
consulta = "SELECT tb1.designacao, tb1.cliente, tb1.ultimo_evento, tb2.ultimo_evento "
consulta += "FROM circuitos as tb1" 
consulta += "INNER JOIN circuitos_ant as tb2 ON tb1.designacao = tb2.designacao "
consulta += "WHERE tb1.ultimo_evento <> tb2.ultimo_evento"

#relaciona as novas inclusões de circuitos

consulta = "SELECT tb1.designacao, tb1.cliente, tb.ufA, tb1.status "
consulta += "FROM circuitos as tb1 "
consulta += "WHERE tb1.designacao NOT IN ("
consulta += "SELECT designacao FROM circuitos_ant)"

dbCircuito.close # encerra conexao ao bando de dados
puts "\nImportacao concluida com sucesso!"
