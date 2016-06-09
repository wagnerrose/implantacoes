# A
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
class db
  def inicialize (bancodedados, host, usuario, senha)
    @host = host
    @usuario = usuario
    @senha = senha
    @bancodedados = bancodedados
    db = Mysql2::Client.new(:host =>  @host, 
                            :username => @usuario, 
                            :password => @senha, 
                            :database => @bancodedados)
  end
  # cria script pra inclusão no banco de dados
  def insereDB (dados)
    #  dados['id_circuito']="" 
    colunas = dados.keys
    valores = dados.values
    consulta = "\nINSERT INTO circuitos ("
    colunas.each_with_index { |nomeCampo,indice|
      case indice
      when 0
        consulta += "#{nomeCampo}"
      else
        consulta += ",#{nomeCampo}"
      end
    }
    consulta += ") VALUES ("
    valores.each_with_index { |valor, indice| # imprime valores numericos
      case indice
      when 0
        consulta += "\'#{valor}\'"
      when 5..6,27 
        consulta += ","
        saida += valor
      else
        saida += ",\'#{valor}\'"
      end
    } 
    saida += ");"

    consulta = saida.gsub(/ nil|\[|\]/,"").gsub(/\"/,"\'")
    puts consulta
    conDB.query(consulta)
  end
end
#===================================================
#
csv_Circuito = "./saidaCircuito.csv"

puts "Verificando a existência do arquivo..."

unless File::exists?(csv_Circuito) # abre arquivo csv de entrada para leitura
  puts "Arquivo CSV contendo Circuitos nao encontrado, verifique se esta correto e tente novamente."
  return
end
puts "Arquivo de Entrada encontrado!"
puts "Executando importacao, aguarde..."

# conectando com banco de dados
dbCircuito = db.new ("localhost", "root", "bela1010", "telebras")

conta = 0
contaCircuito = 0 
# le arquivo csv de entrada
CSV.foreach("#{csv_Circuito}", encoding:'utf-8', col_sep: ';', row_sep: :auto, headers:true) do |linha|
  designacao = linha['designacao']
  cliente = linha['cliente']
  dado= linha.to_hash
  dbCircuito.insereDB(dado) #adiciona ao banco de dados
end
puts "\nImportacao concluida com sucesso!"
