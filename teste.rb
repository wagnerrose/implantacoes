if ARGV.length > 0 then modo = "teste" end
if modo.nil?
  puts "modo normal definido"
else
  puts "modo teste definido"
end
puts ARGV.length
puts modo.class
puts "modo normal definido 2" if modo.nil?
