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
require 'pry'
require 'pry-doc'
require 'pry-nav'
#require 'time'

# testa se modo teste
if ARGV.length > 0 then $modTeste = "ativo" else $modTeste = nil end

enviaEmail = true
emailOrigem = "wagner.rose@telebras.com.br"
emailDestinoTeste = ['wagner_rose@yahoo.com.br', 'wagner.rose@telebras.com.br']
emailDestino = ['wagner.rose@telebras.com.br', 'gilberto.paganotto@telebras.com.br']
emailDestino << 'vagner.schmitt@telebras.com.br'
emailDestino << 'fernandovasconcellos@telebras.com.br'
emailDestino << 'jose.fernandes@telebras.com.br'

assunto = "Acompamento de Implantações"

# ========================================
#   envia email com o resultado da análise
def envia_email ( assunto, corpo, origem, destino)
  @cabecalho = <<EOF
From: #{origem}
To: #{destino} 
subject: #{assunto}
MIME-Version: 1.0
Content-Type: text/html
Content-Transfer-Encoding:8bit
EOF
  texto = @cabecalho + corpo
#  binding.pry if not $modTeste.nil? # debug
  begin
    Net::SMTP.start('webmail.telebras.com.br', 25) do |smtp|
      smtp.send_message texto, origem, destino
    end
  rescue Exception => e
    #puts "Ocorreu o erro: " + e
    puts e
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

dbCircuito.query("DROP TABLE circuitos_ant") if $modTeste.nil? #apaga tabela circuitos_ant se modo Normal de Execução
dbCircuito.query("CREATE TABLE circuitos_ant SELECT * FROM circuitos") if $modTeste.nil? # copia tabela circuitos para circuitos_ant se modo Normal de Execução
dbCircuito.query("DELETE FROM circuitos") if $modTeste.nil? #apaga todos os registros da tabela circuito  se modo Normal de Execução
conta = 0
contaCircuito = 0 
# le arquivo csv de entrada
CSV.foreach("#{csv_Circuito}", encoding:'utf-8', col_sep: ';', row_sep: :auto, headers:true) do |linha|
  designacao = linha['designacao']
  cliente = linha['cliente']
  dado = linha.to_hash
  consulta = criaconsulta(dado)
  puts "\n#{consulta}\n" # ># imprime se modo de Execução teste
  dbCircuito.query("#{consulta}") if $modTeste.nil? # adiciona ao banco de dados se modo Normal de Execução
end

# relaciona circuitos com alteração status e envia email
#monta ccs
css="<style type=\"text/css\">"
css+="#fundo \{ background-color: #d3d3d3;\}"
css+="#box-table-a"
css+="\{ font-family: \"Lucida Sans Unicode\", \"Lucida Grande\", Sans-Serif;"
css+="font-size: 12px; width: 100%; text-align: center; border-collapse: collapse;\}"
css+="#box-table-a th"
css+="\{ font-size: 13px; font-weight: bold; padding: 8px; background: #b9c9fe; "
css+="border-top: 4px solid #aabcfe; border-bottom: 1px solid #fff; color: #039;\}"
css+="#box-table-a td"
css+="\{ padding: 8px; background: #e8edff; border-bottom: 1px solid #fff; color: #669; "
css+="border-top: 1px solid transparent; \}"
css+="#box-table-a tr:hover td"
css+="\{ background: #d0dafd; color: #339;\}"
css+="</style>"

consulta = "SELECT DATE_FORMAT(curdate(),'%d-%m-%Y') AS 'Data Avaliação',tb1.designacao as 'Designacao', tb1.regional AS 'Regional', "
consulta += "tb1.cliente AS 'Cliente', DATE_FORMAT(tb1.data_ativacao,'%d-%m-%Y') as 'Data Ativação', tb1.status AS 'Status Atual', tb2.status AS 'Status Anterior', "
consulta += "tb1.ultimo_evento AS 'Último Evento' "
consulta += "FROM circuitos AS tb1 "
consulta += "INNER JOIN circuitos_ant AS tb2 ON tb1.designacao = tb2.designacao "
consulta += "WHERE tb1.status  <> tb2.status "
consulta += "ORDER BY tb1.designacao"

mensagem = "<!DOCTYPE html>"
mensagem +="<html lang=\"pt-br\">"
mensagem +="<head>"
mensagem +="<title>Acompanhamento de Implantações</title>"
mensagem +="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
mensagem << css
mensagem +="</head>"
mensagem +="<body>"
mensagem +="<div id=\"fundo\">"
mensagem +="<h1 align=\"center\">Circuitos com Alteração de Status </h1>"
mensagem +="<h1 align=\"center\">Ativações, Bloqueios e Desativações</h1>"
mensagem +="</div>"
mensagem +="<table id=\"box-table-a\">"
mensagem +="<thead>"
mensagem +="<tr>"
mensagem +="<th scope=\"col\">Data Avaliação</th>"
mensagem +="<th scope=\"col\">Designação</th>"
mensagem +="<th scope=\"col\">Regional</th>"
mensagem +="<th scope=\"col\">Cliente</th>"
mensagem +="<th scope=\"col\">Data Ativação</th>"
mensagem +="<th scope=\"col\">Status Atual</th>"
mensagem +="<th scope=\"col\">Status Anterior</th>"
mensagem +="<th scope=\"col\">Último Evento</th>"
mensagem +="</tr>"
mensagem +="</thead>"

#binding.pry if not $modTeste.nil?

resposta = dbCircuito.query("#{consulta}")
if resposta.count  > 0 then
  resposta.each do |linha|
    mensagem += "<tr>"
    linha.each_value { |valor| mensagem += "<td align=\"center\">#{valor}</td>"}
    mensagem += "</tr>"
  end
else
  mensagem += "<tr></tr><tr><td colspan=\'8\'><h1 align=\'center\'> Nenhuma alteração de Status ocorrida! </td></tr>"
end
mensagem += "</table>"
mensagem +="</body>"
mensagem +="</html>"

assunto = "Acompanhamento de Implantações - Status"

#binding.pry if not $modTeste.nil?

#envia email
if $modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
end

# relaciona circuitos com alteração evento
consulta = "SELECT DATE_FORMAT(curdate(),'%d-%m-%Y') AS 'Data Avaliação', tb1.designacao AS 'Designação',tb1.regional AS 'Regional', "
consulta += "tb1.cliente AS 'Cliente',tb1.status AS 'Status Atual', tb1.ultimo_evento AS 'Último Evento', "
consulta += "DATE_FORMAT(tb1.data_ativacao,'%d-%m-%Y') AS 'Data Ativação', tb2.ultimo_evento AS 'Evento Anterior' "
consulta += "FROM circuitos AS tb1 "
consulta += "INNER JOIN circuitos_ant AS tb2 ON tb1.designacao = tb2.designacao "
consulta += "WHERE tb1.ultimo_evento <> tb2.ultimo_evento "
consulta += "ORDER BY tb1.designacao"

#binding.pry if not $modTeste.nil? #debug

mensagem = "<!DOCTYPE html>"
mensagem +="<html lang=\"pt-br\">"
mensagem +="<head>"
mensagem +="<title>Acompanhamento de Implantações</title>"
mensagem +="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
mensagem << css
mensagem +="</head>"
mensagem += "<body>"
mensagem +="<div id=\"fundo\">"
mensagem +="<h1 align=\"center\">Circuitos com Alteração de Eventos</h1>"
mensagem +="</div>"
mensagem +="<table id=\"box-table-a\">"
mensagem +="<tr>"
mensagem +="<th scope=\"col\">Data Avaliação</th>"
mensagem +="<th scope=\"col\">Designação</th>"
mensagem +="<th scope=\"col\">Regional</th>"
mensagem +="<th scope=\"col\">Cliente</th>"
mensagem +="<th scope=\"col\">Status Atual</th>"
mensagem +="<th scope=\"col\">Último Evento</th>"
mensagem +="<th scope=\"col\">Data Ativação</th>"
mensagem +="<th scope=\"col\">Evento Anterior</th>"
mensagem +="</tr>"

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
mensagem +="</table>"
mensagem +="</body>"
mensagem +="</html>"
#binding.pry if not $modTeste.nil? #debug

assunto = "Acompanhamento de Implantações - Eventos"

if $modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
end

#relaciona as novas inclusões de circuitos
consulta = "SELECT DATE_FORMAT(curdate(),'%d-%m-%Y') AS 'Data Avaliação', tb1.designacao AS 'Designação',tb1.regional AS 'Regional', "
consulta += "tb1.cliente AS 'Cliente',tb1.status AS 'Status Atual', tb1.ultimo_evento AS 'Último Evento' "
consulta += "FROM circuitos AS tb1 "
consulta += "WHERE tb1.designacao NOT IN (SELECT tb2.designacao FROM circuitos_ant AS tb2)"

mensagem ="<!DOCTYPE html>"
mensagem +="<html lang=\"pt-br\">"
mensagem +="<head>"
mensagem +="<title>Acompanhamento de Implantações</title>"
mensagem +="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
mensagem << css
mensagem +="</head>"
mensagem +="<body>"
mensagem +="<div id=\"fundo\">"
mensagem +="<h1 align=\"center\">Novas inclusões de Circuitos </h1>\n"
mensagem +="</div>"
mensagem +="<table id=\"box-table-a\">"
mensagem +="<tr>"
mensagem +="<th scope=\"col\">Data Avaliação</th>"
mensagem +="<th scope=\"col\">Designação</th>"
mensagem +="<th scope=\"col\">Regional</th>"
mensagem +="<th scope=\"col\">Cliente</th>"
mensagem +="<th scope=\"col\">Status Atual</th>"
mensagem +="<th scope=\"col\">Último Evento</th>"
mensagem +="</tr>"

#binding.pry if not $modTeste.nil? # debug

resposta = dbCircuito.query("#{consulta}")
if resposta.count  > 0 then
  resposta.each do |linha|
    mensagem += "<tr>"
    linha.each_value { |valor| mensagem += "<td align=\"center\">#{valor}</td>"}
    mensagem += "</tr>"
  end
else
  mensagem += "<tr></tr><tr><td colspan=\'8\'><h1 align=\'center\'> Nenhum novo Circuito incluido! </td></tr>"
end
mensagem +="</table>"
mensagem +="</body>"
mensagem +="</html>"

assunto = "Acompanhamento de Implantações - Novas Inclusões"

#binding.pry if not $modTeste.nil? #debug

# envia email
if $modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
end

dbCircuito.close # encerra conexao ao bando de dados
puts "\nImportacao concluida com sucesso!"
