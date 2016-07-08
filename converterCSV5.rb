# DATA: 05/04/2016
# PROGRAMADOR: Wagner Röse
# OBJETIVO: Criar um script para importar os dados de arquivo csv
#		 atualizando o BD contendo informação da situação das implantações de cliente da
#		regional de Porto Alegre.
# Importa arquivo CSV, Parametro: PATH=/caminho/completo/para/o/arquivo.csv"

require 'csv'
require 'date'
require 'mysql2'
require 'net/smtp'
#require 'time'

# testa se modo teste
if ARGV.length > 0 then modTeste = "ativo" else modTeste = nil end

enviaEmail = true
emailOrigem = "wagner.rose@telebras.com.br"
emailDestinoTeste = "wagner_rose@yahoo.com.br"
emailDestino = "wagner.rose@telebras.com.br, gilberto.paganotto@telebras.com.br, "
emailDestino += "vagner.schmitt@telebras.com.br, fernandovasconcello@telebras.com.br"
assunto = "Acompamento de Implantações"

# ========================================
#   envia email com o resultado da análise
def envia_email ( assunto, corpo, origem, destino)
  @cabecalho = <<EOF
From: Wagner Röse <wagner.rose@telebras.com.br>
To: Wagner Röse <wagner_rose@yahoo.com.br>
subject: #{assunto}
MIME-Version: 1.0
Content-Type: text/html
Content-Transfer-Encoding:8bit
EOF
  texto = @cabecalho + corpo

  begin
    Net::SMTP.start('webmail.telebras.com.br', 25) do |smtp|
      smtp.send_message texto, origem, destino
    end
  rescue Exception => e
    print "Ocorreu o erro: " + e
  end
end

#=====================================
# valida data segundo formato mm/dd/yyyy
def valid_date?( str, format="%Y/%m/%d" )
  Date.strptime(str,format) rescue false
end

#======================================
# monta comando de consulta
#
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


#==========================================================
#    Main
#

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

dbCircuito.query("DROP TABLE circuitos_ant") if modTeste.nil? #apaga tabela circuitos_ant se modo Normal de Execução
dbCircuito.query("CREATE TABLE circuitos_ant SELECT * FROM circuitos") if modTeste.nil? # copia tabela circuitos para circuitos_ant se modo Normal de Execução
dbCircuito.query("DELETE FROM circuitos") if modTeste.nil? #apaga todos os registros da tabela circuito  se modo Normal de Execução
conta = 0
contaCircuito = 0 
# le arquivo csv de entrada
CSV.foreach("#{csv_Circuito}", encoding:'utf-8', col_sep: ';', row_sep: :auto, headers:true) do |linha|
  designacao = linha['designacao']
  cliente = linha['cliente']
  dado = linha.to_hash
  consulta = criaconsulta(dado)
  puts "\n#{consulta}\n" # ># imprime se modo de Execução teste
  dbCircuito.query("#{consulta}") if modTeste.nil? # adiciona ao banco de dados se modo Normal de Execução
end

# relaciona circuitos com alteração status e envia email
consulta = "SELECT curdate() AS 'Data Avaliação',tb1.designacao as 'Designacao', tb1.regional AS 'Regional', "
consulta += "tb1.cliente AS 'Cliente', tb1.status AS 'Status Atual', tb2.status AS 'Status Anterior', "
consulta += "tb1.ultimo_evento AS 'Último Evento' "
consulta += "FROM circuitos AS tb1 "
consulta += "INNER JOIN circuitos_ant AS tb2 ON tb1.designacao = tb2.designacao "
consulta += "WHERE tb1.status  <> tb2.status "
consulta += "ORDER BY tb1.designacao"

mensagem = "<html>\n<head><title>Acompamento de Implantações</title></head>\n"
mensagem += "<body><h1 align=\"center\">Circuitos com Alteração de Status </h1>\n"
mensagem += "<body><h1 align=\"center\">Ativações, Bloqueios e Desativações</h1>\n"
mensagem += "<table style=\"HEIGHT:100%;WIDTH:100%\" border='1'>\n"
mensagem +="<tr><th align=\"center\">Data Avaliação</th>"
mensagem += "<th align=\"center\">Designação</th>"
mensagem += "<th align=\"center\">Regional</th>"
mensagem += "<th align=\"center\">Cliente</th>"
mensagem += "<th align=\"center\">Status Atual</th>"
mensagem += "<th align=\"center\">Status Anterior</th>"
mensagem += "<th align=\"center\">Último Evento</th></tr>\n"

puts consulta + "\n" if not modTeste.nil? # imprime se modo de Execução teste

resposta = dbCircuito.query("#{consulta}")
if resposta.count  > 0 then
  resposta.each do |linha|
    mensagem += "<tr>"
    linha.each_value { |valor| mensagem += "<td align=\"center\">#{valor}</td>"}
    mensagem += "</tr>\n"
  end
else
  mensagem += "<tr></tr><tr><td colspan=\'8\'><h1 align=\'center\'> Nenhuma alteração de Status ocorrida! </td></tr>"
end
mensagem += "</table></body></html>\n"

assunto = "Acompamento de Implantações - Status"
#envia email
if modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
  puts mensagem + "\n" if not modTeste.nil? # imprime se modo de teste
end

# relaciona circuitos com alteração evento
consulta = "SELECT curdate() AS 'Data Avaliação', tb1.designacao AS 'Designação',tb1.regional AS 'Regional', "
consulta += "tb1.cliente AS 'Cliente',tb1.status AS 'Status Atual', tb1.ultimo_evento AS 'Último Evento', "
consulta += "tb1.data_ativacao AS 'Data Ativação', tb2.ultimo_evento AS 'Evento Anterior' "
consulta += "FROM circuitos AS tb1 "
consulta += "INNER JOIN circuitos_ant AS tb2 ON tb1.designacao = tb2.designacao "
consulta += "WHERE tb1.ultimo_evento <> tb2.ultimo_evento "
consulta += "ORDER BY tb1.designacao"

puts "\n" + consulta + "\n" if not modTeste.nil? # imprime se modo de teste

mensagem = "<html>\n<head><title>Acompamento de Implantações</title></head>\n"
mensagem += "<body bgcolor=\"#81BEF7\"><h1 bgcolor=\"#81BEF7\" align=\"center\">Circuitos com Alteração de Eventos</h1>\n"
mensagem += "<table style=\"HEIGHT:100%;WIDTH:100%\" border='1'> \n"
mensagem +="<tr><th align=\"center\">Data Avaliação</th>"
mensagem += "<th align=\"center\">Designação</th>"
mensagem += "<th align=\"center\">Regional</th>"
mensagem += "<th align=\"center\">Cliente</th>"
mensagem += "<th align=\"center\">Status Atual</th>"
mensagem += "<th align=\"center\">Último Evento</th>"
mensagem += "<th align=\"center\">Data Ativação</th>\n"
mensagem += "<th align=\"center\">Evento Anterior</th></tr>\n"

resposta = dbCircuito.query("#{consulta}")
if resposta.count  > 0 then
  resposta.each do |linha|
    mensagem += "<tr>"
    linha.each_value { |valor| mensagem += "<td align=\"center\">#{valor}</td>"}
    mensagem += "</tr>\n"
  end
else
  mensagem += "<tr></tr><tr><td colspan=\'8\'><h1 align=\'center\'> Nenhuma alteração de eventos ocorrida! </td></tr>"
end
mensagem += "</table></body></html>\n"

assunto = "Acompamento de Implantações - Eventos"
if modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
  puts mensagem + "\n" if not modTeste.nil? # imprime se modo de teste
end


#relaciona as novas inclusões de circuitos
consulta = "SELECT curdate() AS 'Data Avaliação', tb1.designacao AS 'Designação',tb1.regional AS 'Regional', "
consulta += "tb1.cliente AS 'Cliente',tb1.status AS 'Status Atual', tb1.ultimo_evento AS 'Último Evento' "
consulta += "FROM circuitos_ant AS tb1 "
consulta += "WHERE tb1.designacao NOT IN (SELECT tb2.designacao FROM circuitos AS tb2)"

puts "\n" + consulta + "\n" if not modTeste.nil? # imprime se modo de Execução teste

mensagem = "<html>\n<head><title>Acompamento de Implantações</title></head>\n"
mensagem += "<body><h1 align=\"center\">Novas inclusões de Circuitos </h1>\n"
mensagem += "<table style=\"HEIGHT:100%;WIDTH:100%\" border='1' bgcolor= '#81BEF7'> \n"
mensagem +="<tr><th align=\"center\">Data Avaliação</th>"
mensagem += "<th align=\"center\">Designação</th>"
mensagem += "<th align=\"center\">Regional</th>"
mensagem += "<th align=\"center\">Cliente</th>"
mensagem += "<th align=\"center\">Status Atual</th>"
mensagem += "<th align=\"center\">Último Evento</th></tr>\n"

resposta = dbCircuito.query("#{consulta}")
if resposta.count  > 0 then
  resposta.each do |linha|
    mensagem += "<tr>"
    linha.each_value { |valor| mensagem += "<td align=\"center\">#{valor}</td>"}
    mensagem += "</tr>\n"
  end
else
  mensagem += "<tr></tr><tr><td colspan=\'8\'><h1 align=\'center\'> Nenhum novo Circuito incluido! </td></tr>"
end
mensagem += "</table></body></html>\n"

assunto = "Acompamento de Implantações - Novas Inclusões"
# envia email
if modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
  puts mensagem + "\n" if not modTeste.nil? # imprime se modo de teste
end

dbCircuito.close # encerra conexao ao bando de dados
puts "\nImportacao concluida com sucesso!"
