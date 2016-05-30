# A
# DATA: 05/04/2016
# PROGRAMADOR: Wagner Röse
# OBJETIVO: Criar um script para importar os dados de arquivo csv
#		contendo informação da situação das implantações de cliente da
#		regional de Porto Alegre.
# Importa arquivo CSV, Parametro: PATH=/caminho/completo/para/o/arquivo.csv"

require 'csv'
require 'date'
require 'time'

# valida data segundo formato mm/dd/yyyy
def valid_date?( str, format="%Y/%m/%d" )
  Date.strptime(str,format) rescue false
end

#formata campo cep
def formata_cep (str)
  puts "saida cep = #{str}"
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

csv_file = "./texto.csv"
csv_Evento = "./saidaEventos.csv"
csv_Circuito = "./saidaCircuito.csv"

puts "Verificando a existência do arquivo..."

unless File::exists?(csv_file)
  puts "Arquivo nao encontrado, verifique se esta correto e tente novamente."
  return
end
puts "Arquivo de Entrada encontrado!"
puts "Executando importacao, aguarde..."

# Abre arquivos para saida de dados
if  File::exists?(csv_Circuito)
  puts "Arquivo de saida de Circuitos criado e aberto para inclusão"
  saidaCircuitos = File.open("#{csv_Circuito}","w")
else
  puts "Arquivo de saida de Circuitos aberto para inclusão"
  saidaCircuitos = File.new("#{csv_Circuito}","w")
end

if  File::exists?(csv_Evento)
  puts "Arquivo de saida de Eventos criado e aberto para inclusão"
  saidaEventos = File.open("#{csv_Evento}","w")
else
  puts "Arquivo de saida de Eventos aberto para inclusão"
  saidaEventos = File.new("#{csv_Evento}","w")
end
conta = 0
contaCircuito = 0 
primeira_linha = "id_circuito;designacao;cliente;descricao;uf_circuito;tipo_serviço;banda_contratada;banda_ativada;"
primeira_linha << "os_ativacao;data_os;tipo_os;data_ativacao;estacaoA;acessoA;enderecoA;cidadeA;ufA;cepA;estacaoB;"
primeira_linha << "acessoB;enderecoB;cidadeB;ufB;cepB;contato;telefone;movel;e-mail;valor;previsao;status;ultimo_evento"
# le arquivo csv de entrada
CSV.foreach("#{csv_file}", encoding:'iso-8859-1:utf-8', col_sep: ';', row_sep: :auto) do |linha|
  linhaCircuito = ""
  dadosCerto = true
  if (contaCircuito == 0)
#    for i in 1..29 do
#      linhaCircuito << "#{linha[i]};"
#    end
    linhaCircuito << primeira_linha
    saidaCircuitos.puts "#{linhaCircuito}"
    contaCircuito += 1
  else  
    if linha[1].length > 10 # designacao maior que 10 caracteres
      puts "Designação incorreta #{linha[1]}"
      dadosCerto = false
    else
      linhaCircuito << "#{linha[1]};" # designacao
    end

    linhaCircuito << "#{linha[0]};" # cliente
    linhaCircuito << "#{linha[2]};" # descriao
    linhaCircuito << "#{linha[1][0..1]};" # uf
    linhaCircuito << "#{linha[3]};" # servico
    linhaCircuito << "#{linha[4]};" # bandaContratada
    linhaCircuito << "#{linha[5]};" # bandaAtivada	  
    linhaCircuito << "#{linha[6]};" # OSAtivacao	

    if valid_date?("#{linha[7]}") # corrige data OS
      dt = Date.parse("#{linha[7]}") 
      dataOS = dt.strftime("%Y-%m-%d")
    else
      puts "data OS 75 = #{linha[7]}"
      dataOS = "2016-01-01"
    end

    linhaCircuito << "#{dataOS};" # dataOS		  

    linhaCircuito << "#{linha[8]};" # tipoOS

    #dtAtivacao	= linha[9] # Corrige data da Ativacao da OS

    if valid_date?("#{linha[9]}") #data ativação da os
      dt = Date.parse("#{linha[9]}") 
      dataAtivacao = dt.strftime("%Y-%m-%d")
    else
      dataAtivacao = "2016-01-01"
    end

    linhaCircuito << "#{dataAtivacao};" # dataAtivacao

    if "#{linha[10]};" =~ /desconhecido/  # testa de estacao A contem "desconhecido"
      linhaCircuito << ";"
    else
      linhaCircuito << "#{linha[10]};" # estacaoA	
    end

    if "#{linha[11]};" =~ /N\/A/ # testa se acesso contem N/A
      linhaCircuito << ";"
    else
      linhaCircuito << "#{linha[11]};" # acessoA	
    end		

    linhaCircuito << "#{linha[12]};" # enderecoA	
    linhaCircuito << "#{linha[13]};" # cidadeA	
    linhaCircuito << "#{linha[14]};" # ufA	
    linhaCircuito << formata_cep(linha[15]) << ";" # cepA	

    if "#{linha[16]}" =~ /desconhecido/  # testa de estacao B contem "desconhecido"
      linhaCircuito << ";"
    else
      linhaCircuito << "#{linha[16]};" # estacaoB
    end		 

    linhaCircuito << "#{linha[17]};" # acessoB	
    linhaCircuito << "#{linha[18]};" # enderecoB	
    linhaCircuito << "#{linha[19]};" # cidadeB	
    linhaCircuito << "#{linha[20]};" # ufB

    linhaCircuito << formata_cep(linha[21]) << ";" # cepB	
    linhaCircuito << "#{linha[22]};" # contato	
    linhaCircuito << "#{linha[23]};" # foneFixo	

    linhaCircuito << "#{linha[24]};" # foneMovel

    linhaCircuito << "#{linha[25]}".gsub(/;/, " ou ")<< ";" # retira ; do conteúdo do email
    valor = "#{linha[26]}".gsub(/[R\$.]/, "").gsub(/,/,".")# retira R$ do valor
    
    linhaCircuito << "#{valor}".strip << ";"  # valor
    dtAtivacao = "#{linha[27]}".gsub(/00\/00\/0000/, "01/01/2016") #Data ativacao
    if valid_date?("#{dtAtivacao}")
      dt = Date.parse("#{dtAtivacao}") 
      dataAtivacao = dt.strftime("%Y-%m-%d")
    else
      dataAtivacao = "2016-01-01"
    end
    linhaCircuito << "#{dataAtivacao}" << ";" #Data ativacao
    
    linhaCircuito << "#{linha[28]};" # status	
    linhaCircuito << "#{linha[29]};" # ultimoEvento	  

    # ponto de checagem da linhaCircuito
    puts linhaCircuito

    if dadosCerto # grava linha com informação de circuito se os dados estao corretos
      contaCircuito += 1
      saidaCircuitos.puts "#{contaCircuito};#{linhaCircuito}"
    end
    puts "\nSaida = #{contaCircuito};#{linhaCircuito}\n"
    designacao = linha[1]
    observacao = linha[30]
    unless(observacao.nil?) #verifica se existe observaçao a ser carregada
      puts "observacao = #{observacao}" 
      arrayObservacao = observacao.split(/\n/)
      puts "Conta = #{conta}"
      arrayObservacao.each do |obs|
        arraytexto = obs.split('-')
        dtEvento = "#{arraytexto[0]}".strip!
        puts "Saida => #{dtEvento}."
        # tratando campo dataEvento preenchido incorretamente
        descritivoEvento = "#{arraytexto[1]}".strip
        unless (dtEvento.nil?)||(descritivoEvento.nil?) # retira todos sem data ou descricao
          dtEvento << "/2015" if (dtEvento.length  == 5) # insere ano
          puts dtEvento
          if  valid_date?("#{dtEvento}") # retira linhas com data incorreta
            conta += 1
            dataEvento = Date.parse("#{dtEvento}")
            saidaEventos.puts "#{conta};#{designacao};#{dataEvento.strftime("%Y-%m-%d")};#{descritivoEvento}"
            puts "Saida do Evento = #{conta};#{designacao};#{dataEvento.strftime("%Y-%m-%d")};#{descritivoEvento}"
          end
        end
      end
    end
  end
end
puts "\nImportacao concluida com sucesso!"
saidaCircuitos.close
saidaEventos.close
