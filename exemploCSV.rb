# DATA: 10/06/2011
# PROGRAMADOR: Valberto Carneiro
# OBJETIVO: Criar um script para atualizacao dos salarios dos funcionarios e
#           criacao de novos salarios, caso a matricula do funcionario ainda
#           nao exista na base de dados.
# CONSIDERAÇÕES:
#   1. Aplicação em Rails (>= 2.3.8)
#   2. Conexão com banco de dados configurada
#   3. Tabela "funcionarios" criada e populada
#   4. Campos da tabela: id:integer, nome:string, salario:float, cpf:string
 
# app/models/funcionario.rb
 
class Funcionario < ActiveRecord::Base
# os metodos de acesso sao criados automaticamente pelo ActiveRecord
end
 
# lib/tasks/minhas_tarefas.rake
 
require 'csv'
 
namespace :tarefas do
 
  desc "Importa arquivo CSV, Parametro: PATH=/caminho/completo/para/o/arquivo.csv"
 
  task :importar_funcionarios => :environment do
    csv_file = ENV["PATH"]
 
    puts "Verificando a existência do arquivo..."
 
    unless File::exists?(csv_file)
      puts "Arquivo nao encontrado, verifique se esta correto e tente novamente."
      return
    end
 
    puts "Arquivo encontrado!"
    puts "Executando importacao, aguarde..."
 
    CSV.open("#{csv_file}","r") do |linha|
      nome    = linha[0]
      salario = linha[1]
      cpf     = linha[2]
 
      funcionario =  Funcionario.find_by_cpf(cpf)
 
      if funcionario
        funcionario.salario = salario
      else
        funcionario = Pessoa.new(:nome => nome, :salario => salario)
        funcionario.save
      end
    end
    puts "Importacao concluida com sucesso!"
  end
end
