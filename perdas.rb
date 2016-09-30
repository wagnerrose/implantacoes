# DATA: 21/09/2016
# PROGRAMADOR: Wagner Röse
# OBJETIVO: Criar um script para apresentar as pendencia de implantação existente nas regionais
# Utiliza dados gerados e pesquisa de Views existentes no BD

require 'csv'
require 'date'
require 'mysql2'
require 'net/smtp'
require 'pry'
require 'pry-doc'
require 'pry-nav'
#require 'time'
require 'money'

Money.use_i18n = false

# testa se modo teste
if ARGV.length > 0 then $modTeste = "ativo" else $modTeste = nil end

enviaEmail = "true"
emailOrigem = "wagner.rose@telebras.com.br"
emailDestinoTeste = ["wagner_rose@yahoo.com.br" ]
emailDestinoTeste << [" wagner.rose@telebras.com.br"]
emailDestino = ["wagner.rose@telebras.com.br"] 
emailDestino << ["gilberto.paganotto@telebras.com.br"]
emailDestino << ["vagner.schmitt@telebras.com.br"]
emailDestino << ["fernandovasconcellos@telebras.com.br"]
emailDestino << ["jose.fernandes@telebras.com.br"]

regional= Hash.new()
regional["São Paulo"] = "valor_perda_sp"
regional["Rio de Janeiro"] = "valor_perda_rj"
regional["Belém"] = "valor_perda_belem"
regional["Governo"] = "valor_perda_governo"
regional["Brasília"] = "valor_perda_brasilia"


# ========================================
#   envia email com o resultado da análise
def envia_email ( assunto, corpo, origem, destino)
  @cabecalho = <<EOF
From: #{origem}
To: #{destino} 
subject: #{assunto}
MIME-Version: 1.0
Content-Type: text/html; charset=utf-8
EOF
  #Content-Transfer-Encoding:8bit
  #EOF
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
# formatar número para moeda
#
class Numeric
  def to_currency( pre_symbol='R$ ', thousands='.', decimal=',', post_symbol=nil )
    "#{pre_symbol}#{
                ( "%.2f" % self ).gsub( /(\d)(?=(?:\d{3})+(?:$|\.))/, "\\1#{thousands}")
    }#{post_symbol}"
  end
end
#====================================
# formatar número para moeda 2
#====================================
def formata_moeda(valor)
  @moeda=Money.new(valor*100).format(:thousands_separator => ".", :decimal_mark => ",", :symbol => "R$ ")
  return @moeda 
end

#====================================
# monta relatorio
#====================================
def relatorio_regionais( db, tabela_db)
  @soma= 0
  @msg=""
  consulta = "SELECT * from #{tabela_db}"
  resposta = db.query("#{consulta}")
  if resposta.count  > 0 then
    @soma = 0
    resposta.each do |linha|
      @msg+= "<tr>"
      linha.each do | key , dado|
        case key
        when "valor", "perdas45" then
          @msg+= "<td align=\"center\"> #{formata_moeda(dado*100.round/100.0)}</td>" 
        else
          @msg+= "<td align=\"center\">#{dado}</td>"
        end
      end
      @msg+= "</tr>"
    end
  else
    @msg+= "<tr></tr><tr><td colspan=\'8\'><h1 align=\'center\'> Nenhuma alteração de Status ocorrida! </td></tr>"
  end
  return @msg
end

def total_perdas(db, tabela_db)
  @soma= 0
  @msg=""
  consulta = "SELECT sum(perdas45) as perdas from #{tabela_db}"
  resposta = db.query("#{consulta}")
  resposta.each do |linha|
    #@soma=resposta['perdas']
    @soma=formata_moeda((linha['perdas']*100).round/100.0)
    puts @soma 
  end 
  return @soma 
end
#====================================
#           Main
#====================================

# conectando com banco de dados
dbCircuito = Mysql2::Client.new(:host => "localhost", 
                                :username => "root", 
                                :password => "bela1010", 
                                :database => 'telebras')

#==========================================================
# Monta ccs
#
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


#============================================================
#  Cria consulta e monta mensagem de e-mail
#

mensagem = "<!DOCTYPE html>"
mensagem +="<html lang= \"pt-br\">"
mensagem +="<head>"
mensagem +="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"
mensagem +="<title> Perdas de Implantação após 45 dias</title>"
mensagem << css
mensagem +="</head>"
mensagem +="<body>"
mensagem +="<div id=\"fundo\">"
mensagem +="<h1 align=\"center\">Perdas de Implantação Somada das Regionais </h1>"
mensagem +="</div>"
mensagem +="<table id=\"box-table-a\">"
mensagem +="<thead>"
mensagem +="<tr>"
mensagem +="<th scope=\"col\">Regional</th>"
mensagem +="<th scope=\"col\">Perdas após 45 dias</th>"
mensagem +="</tr>"
mensagem +="</thead>"

#binding.pry if not $modTeste.nil?

mensagem+=relatorio_regionais(dbCircuito, "valor_perda_somada")
mensagem += "<tr>"
mensagem += "<td style=\"color:red; background-color:#b9c9fe\" align=\"center\"><b>Total:</b></td>"
mensagem += "<td style=\" background-color:#b9c9fe\" align=\"center\"><b> #{total_perdas(dbCircuito, "valor_perda_somada")}</b></td>"
mensagem += "</tr>"
mensagem += "</table>"
mensagem += "<br><br>"

regional.each do | reg, tabela |

  mensagem +="<div id=\"fundo\">"
  mensagem +="<h1 align=\"center\"> Implantações Regionais na Regional #{reg}</h1>"
  mensagem +="</div>"
  mensagem +="<table id=\"box-table-a\">"
  mensagem +="<thead>"
  mensagem +="<tr>"
  mensagem +="<th scope=\"col\">Regional #{reg}</th>"
  mensagem +="<th scope=\"col\">Perdas após 45 dias</th>"
  mensagem +="</tr>"
  mensagem +="</thead>"

  mensagem+=relatorio_regionais(dbCircuito, tabela)
end
mensagem +="</body>"
mensagem +="</html>"

assunto = "Perdas por não implantacao apos 45 Dias"
#binding.pry if not $modTeste.nil?

#assunto = "Perdas por nao implantacao apos 45 Dias"
#envia email
if $modTeste.nil?  # se modo de execução
  envia_email(assunto, mensagem, emailOrigem, emailDestino) if not enviaEmail.nil? # envia email se habilitado 
else # se modo teste
  envia_email(assunto, mensagem, emailOrigem, emailDestinoTeste) if not enviaEmail.nil? # envia email se habilitado 
end

dbCircuito.close # encerra conexao ao bando de dados
puts "\nAnálise envida com sucesso!"
