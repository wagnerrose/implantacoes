# DATA: 23/06/2016
# # PROGRAMADOR: Wagner Röse
# # OBJETIVO: Criar um script para teste de envio de emails
#
require 'gmail'
gmail = Gmail.connect("wagner.rose@gmail.com","wgrose68")


gmail.deliver do
  to "wagner.rose@telebras.com.br"
  subject "Email de teste Ruby"
  text_part do
    body "Hello world in text"
  end
  html_part do
    content_type 'text/html; charset=UTF-8'
    body "<b>Hello world in HTML</b>"
  end
end
gmail.logout
