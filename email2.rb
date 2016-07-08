# teste de envio de emaildd

require 'net/smtp'

filename = "./testeEmail.txt"
# Read a file and encode it into base64 format
filecontent = File.read(filename)
encodedcontent = [filecontent].pack("m")   # base64

marker = "AUNIQUEMARKER"

body = <<EOF
<b>Este é um e-Mail de teste de envio em Ruby.</b>
<h1>Mensagem de contato</h1>
EOF

# # Define the main headers.
part1 = <<EOF
From: Wagner Röse <wagner.rose@telebras.com.br>
To: wagner rose <wagner_rose@yahoo.com.br>
Subject: Email de teste 
MIME-Version: 1.0
EOF

# Define the message action
part2 = <<EOF
Content-Type: text/html
Content-Transfer-Encoding:8bit

#{body}

EOF

# Define the attachment section
part3 = <<EOF
Content-Type: multipart/mixed; name=\"#{filename}\"
 Content-Transfer-Encoding:base64
 Content-Disposition: attachment; filename="#{filename}"

#{encodedcontent}
--#{marker}--
EOF

#mailtext = part1 + part2 + part3
mailtext = part1 + part2

# # Let's put our code in safe area
begin 
  Net::SMTP.start('webmail.telebras.com.br',25) do |smtp|
    smtp.send_message mailtext, 'wagner.rose@telebras.com.br',
      'wagner_rose@yahoo.com.br'
  end
rescue Exception => e  
  print "Exception occured: " + e  
end  

