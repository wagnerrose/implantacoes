# A
# DATA: 24/06/2016
# PROGRAMADOR: Wagner Röse
# OBJETIVO: Criar um script para importar os dados de arquivo csv
#		contendo informação da situação das implantações de cliente da
#		regional de Porto Alegre.
# Importa arquivo CSV, Parametro: PATH=/caminho/completo/para/o/arquivo.csv"

require 'csv'
require 'date'
require 'time'

require 'pry'
require 'pry-doc'
require 'pry-nav'

# valida data segundo formato mm/dd/yyyy
def valid_date?( str, format="%Y/%m/%d" )
  Date.strptime(str,format) rescue false
end

#formata campo cep
def formata_cep (str)
  #  puts "saida cep = #{str}"
  unless(str.nil?)
    str.gsub!(/[\.-]/,"")
    if (str.length == 8) #verifica n. de digitos
      ft_cep = "#{str[0..1]}.#{str[2..4]}-#{str[5..7]}"
    else
      ft_cep = ""
    end
  else
    ft_cep = "" 
  end
end
#binding.pry

# Le e verifica parâmetros passados
if ARGV.length < 1
  abort("\n====== >>> É necessario informar o nome do arquivo a ser convertido.\n")
end

csv_file = ARGV[0]
unless File.exist?(csv_file)
  abort ("\n====== >>> O Arquivo informado não existe. Favor informa-lo novamente.\n")
end

puts "Arquivo de Entrada encontrado!"
puts "Executando importacao, aguarde..."

csv_Evento = "./saidaEventos.csv"
csv_Circuito = "./saidaCircuito.csv"

puts "Arquivo de saida de Circuitos aberto para inclusão"
saidaCircuitos = File.new("#{csv_Circuito}","w")

puts "Arquivo de saida de Eventos aberto para inclusão"
saidaEventos = File.new("#{csv_Evento}","w")
conta = 0
contaCircuito = 0 
primeira_linha = "designacao;cliente;descricao;regional;tipo_servico;banda_contratada;banda_ativada;"
primeira_linha << "os_ativacao;data_os;tipo_os;data_ativacao;contrato;aditivo;estacaoA;ufA;estacaoB;"
primeira_linha << "ufB;valor;previsao;status;ultimo_evento"

#binding.pry

# le arquivo csv de entrada
CSV.foreach("#{csv_file}", encoding:'utf-8', col_sep: ';', row_sep: :auto) do |linha|
  linhaCircuito = ""
  dadosCerto = true
  case 
  when linha[0].to_s.strip.empty? #elimina linha em branco
    #    puts "Esta linha esta em branco =>> #{contaCircuito}"
    #desconsidera linha
  when  contaCircuito == 0  # tambem desconsidera linha de cabeçalho do arq de entrada
    linhaCircuito << primeira_linha
    saidaCircuitos.puts "#{linhaCircuito}"
    contaCircuito += 1
  else
    if linha[2].length > 10 # designacao maior que 10 caracteres
      puts "Designação incorreta #{linha[2]}"
      dadosCerto = false
    else
      linhaCircuito << "#{linha[2]};" # designacao
    end
    linhaCircuito << "#{linha[0]};" # cliente
    linhaCircuito << "#{linha[3]};" # descricao
    linhaCircuito << "#{linha[1]};" # regional 
    
    linhaCircuito << "#{linha[4]};" # tipo servico
    linhaCircuito << "#{linha[5]};" # banda_Contratada
    linhaCircuito << "#{linha[6]};" # banda_Ativada	  
    linhaCircuito << "#{linha[7]};" # os_ativacao	

    if valid_date?("#{linha[8]}") # corrige data_os
      dt = Date.parse("#{linha[8]}") 
      dataOS = dt.strftime("%Y-%m-%d")
    else
      dataOS = "2016-01-01"
    end

    linhaCircuito << "#{dataOS};" # data_os		  

    linhaCircuito << "#{linha[9]};" # tipo_os

    if valid_date?("#{linha[10]}") #data_ativação da os
      dt = Date.parse("#{linha[10]}") 
      dataAtivacao = dt.strftime("%Y-%m-%d")
    else
      dataAtivacao = "2016-01-01"
    end

    linhaCircuito << "#{dataAtivacao};" # dataAtivacao
    linhaCircuito << "#{linha[11]};" # contrato 
    linhaCircuito << "#{linha[12]};" # aditivo

    if "#{linha[13]};" =~ /desconhecido/  # testa de estacao A contem "desconhecido"
      linhaCircuito << ";"
    else
      linhaCircuito << "#{linha[13]};" # estacaoA	
    end

    linhaCircuito << "#{linha[2][0..1]};" # ufA

    if "#{linha[14]};" =~ /desconhecido/  # testa de estacao B contem "desconhecido"
      linhaCircuito << ";;" # inclui como vazio os campos estacaoB e ufB
    else
      linhaCircuito << "#{linha[14]};" # estacaoB	
      linhaCircuito << "#{linha[14][0..1]};" # ufB
    end
    valor = "#{linha[15]}".gsub(/[R\$.]/, "").gsub(/,/,".")# retira R$ do valor
    linhaCircuito << "#{valor}".strip << ";"  # valor

    dtPrevisao= "#{linha[16]}".gsub(/00\/00\/0000/, "01/01/2016") #Data ativacao
    if valid_date?("#{dtPrevisao}")
      dt = Date.parse("#{dtPrevisao}") 
      dataPrevisao= dt.strftime("%Y-%m-%d")
    else
      dataPrevisao= "2016-01-01"
    end
    linhaCircuito << "#{dataPrevisao}" << ";" #previsao

    linhaCircuito << "#{linha[17]};" # status	
    linhaCircuito << "#{linha[18]}" # ultimoEvento	  
    
#    binding.pry

    if dadosCerto # grava linha com informação de circuito se os dados estao corretos
      contaCircuito += 1
      saidaCircuitos.puts "#{linhaCircuito.gsub(/\"|\'/,"")}" #grava apos retirar "" ou ''
      puts "===>>>> passei gravacao saida\n"
    end
    designacao = linha[2]
    observacao = linha[19]
    unless(observacao.nil?) #verifica se existe observaçao a ser carregada
      puts "observacao = #{observacao}" 
      arrayObservacao = observacao.split(/\n/)
      arrayObservacao.each do |obs|
        puts "Saida obs partida = #{obs}\n"
        arraytexto = obs.split('-')
        dtEvento = "#{arraytexto[0]}".strip!
        # tratando campo dataEvento preenchido incorretamente
        descritivoEvento = "#{arraytexto[1]}".strip
        unless (dtEvento.nil?)||(descritivoEvento.nil?) # retira todos sem data ou descricao
          dtEvento << "/2015" if (dtEvento.length  == 5) # insere ano
          puts dtEvento
          if  valid_date?("#{dtEvento}") # retira linhas com data incorreta
            conta += 1
            dataEvento = Date.parse("#{dtEvento}")
            saidaEventos.puts "#{conta};#{designacao};#{dataEvento.strftime("%Y-%m-%d")};#{descritivoEvento}"
            puts "======>>>>> Saida do Evento = #{conta};"
          end
        end
      end
    end
  end
end
puts "\nImportacao concluida com sucesso!"
saidaCircuitos.close
saidaEventos.close
