select `circuitos`.`designacao` AS `designacao`,
       `circuitos`.`cliente` AS `cliente`,
       `circuitos`.`tipo_servico` AS `tipo_servico`,
       `circuitos`.`banda_contratada` AS `banda_contratada`,
       (to_days(curdate()) - to_days(`circuitos`.`data_os`)) AS `dia_decorridos`,
       `circuitos`.`valor` AS `valor`,
       format(if(((to_days(curdate()) - to_days(`circuitos`.`data_os`)) > 45),
       ((`circuitos`.`valor` / 30) * ((to_days(curdate()) - to_days(`circuitos`.`data_os`)) - 45)),0),2,'de_DE') AS `perdas45`,
       `circuitos`.`ultimo_evento` AS `ultimo_evento` 
from `circuitos` 
where ((`circuitos`.`status` = 'instalação') 
  and (`circuitos`.`regional` = 'Porto Alegre'))


select `circuitos`.`regional` AS `regional`,
       format(if(((to_days(curdate()) - to_days(`circuitos`.`data_os`)) > 45),
       ((`circuitos`.`valor` / 30) * ((to_days(curdate()) - to_days(`circuitos`.`data_os`)) - 45)),0),2,'de_DE') AS `perdas45`
from `circuitos` 
where (`circuitos`.`status` = 'instalação')
group by `circuitos`.`regional` 



select `circuitos`.`regional` AS `regional`,format(if(((to_days(curdate()) - to_days(`circuitos`.`data_os`)) > 45),((`circuitos`.`valor` / 30) * ((to_days(curdate()) - to_days(`circuitos`.`data_os`)) - 45)),0),2,'de_DE') AS `perdas45` from `circuitos` where (`circuitos`.`status` = 'instalação') group by `circuitos`.`regional`



select `circuitos`.`regional` AS `regional`,
   format(    
		 sum(
		     if(
			       (to_days(curdate()) - to_days(`circuitos`.`data_os`)) > 45,
                ((`circuitos`.`valor` / 30) * ((to_days(curdate()) - to_days(`circuitos`.`data_os`)) - 45))
		          ,0
				)
			),
			2, 'de_DE'
		) AS `perdas45`
from `circuitos` 
where `circuitos`.`status` = 'instalação'
group by `circuitos`.`regional` 