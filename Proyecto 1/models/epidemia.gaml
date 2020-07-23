/***
* Name: epidemia
* Author: gamaa
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model epidemia

global{
	file roads_file <- file("../includes/small_roads.shp");
	file blocks_file <- file("../includes/blocks.shp");
	geometry shape <- envelope(roads_file);
	map<string,rgb> color_agentes <- ["susceptible"::#green,"infectado"::#red,"recuperado"::#blue,"inmune"::#gray];
	float sana_distancia <- 2.0 parameter:"Sana distancia" category:"SIR parameters" min:0.0 max:50.0;
	float beta <- 0.2 parameter:"Beta" category:"SIR parameters" min:0.0 max:1.0;
	float rho <- 0.2 parameter:"Rho" category:"SIR parameters" min:0.0 max:1.0;
	float delta <- 0.2 parameter:"Delta" category:"SIR parameters" min:0.0 max:1.0;
	graph roads_network;
	init{
		step <- 1#minute;
		create road from:roads_file;
		roads_network <- as_edge_graph(road);
		create block from:blocks_file;
		create people number:200;
		ask one_of(people){
			status <- "infectado";
		}	
	}
}

species road{
	aspect basic{
		draw shape color:#gray;
	}
}

species block{
	aspect basic{
		draw shape color:rgb (21, 21, 102,100);
	}
}

species target{
	aspect basic{
		draw triangle(10) color:#yellow ;
	}
}

species people skills:[moving]{
	point current_objective;
	path route_to_objective;
	string status <- "susceptible" among:["susceptible","infectado","recuperado","inmune"];
	list<people> contactos_de_riesgo <- [] update:people at_distance(sana_distancia);
	float tiempo_infectado <- 0#seconds;
	init {
		location <- any_location_in(one_of(block));	
		do update_path;
		
	}
	reflex movimiento{
		if location = current_objective{
			route_to_objective <- nil;
			do update_path;			
		}
		do follow path:route_to_objective;
	}
	reflex infectar_a_otro when:status="infectado"{
		if length(contactos_de_riesgo) > 0{
			ask contactos_de_riesgo{
				if status = "susceptible" and flip(beta){
					status <- "infectado";
				}
			}
		}
	}
	reflex recuperacion when:status="infectado" {
		if tiempo_infectado>5#days and flip(rho){
			status <- "recuperado";
		}
		else{
			tiempo_infectado <- tiempo_infectado + step;
		}
	}
	reflex recuperado when:status="recuperado"{
		status <- flip(delta)?"inmune":"susceptible";
		tiempo_infectado <- 0#s;
	}
	action update_path{
		loop while: route_to_objective = nil or route_to_objective = []{
			current_objective <- any_location_in(one_of(block));
			route_to_objective <- path_between(roads_network,location,current_objective);
		}
	}
	aspect estado_salud{
		draw circle(3) color:color_agentes[status];
		loop contacto over:contactos_de_riesgo{
			draw line(location,contacto.location) color:#white;
		}
	}
}

experiment simulacion type:gui{
	output{
		layout #split;
		display GUI type:opengl background:#black draw_env:false{
			species block aspect:basic;
			species people aspect:estado_salud;
			species target aspect:basic;
			overlay position:{10#px,10#px} size:{300#px,300#px} color:#black transparency:0.5{
				draw "0123456789abcdefghijklmnopqrstuvwxyz," color:#black font:font("Arial",26,#plain) at:{0#px,0#px};
				draw "0123456789abcdefghijklmnopqrstuvwxyz," color:#black font:font("Arial",20,#bold) at:{0#px,0#px};
				draw ""+int(time/86400)+" days, "+mod(time/3600,24)+" hours" color:#white font:font("Arial",26,#plain) at:{20#px,50#px};
				draw circle(5) color:color_agentes["susceptible"] at:{20#px,90#px};
				draw "susceptible" color:#white font:font("Arial",20,#bold) at:{35#px,95#px};
				draw circle(5) color:color_agentes["infectado"] at:{20#px,115#px};
				draw "infectado" color:#white font:font("Arial",20,#bold) at:{35#px,120#px};
				draw circle(5) color:color_agentes["recuperado"] at:{20#px,140#px};
				draw "recuperado" color:#white font:font("Arial",20,#bold) at:{35#px,145#px};
				draw circle(5) color:color_agentes["inmune"] at:{20#px,165#px};
				draw "inmune" color:#white font:font("Arial",20,#bold) at:{35#px,170#px};
			}
		}
		display Graficas type:java2D refresh:every(5*step) background:#white {
			chart "Epidemia" x_serie:time#hours x_serie_labels:time#hours type:series y_label:"Numero de personas" label_font:"Arial" label_font_size:24 legend_font:"Arial" legend_font_size:24 title_visible:false{
				data "Susceptibles" value:length(people where(each.status="susceptible")) color:color_agentes["susceptible"] marker:false;
				data "Infectados" value:length(people where(each.status="infectado")) color:color_agentes["infectado"] marker:false;
				data "Recuperados" value:length(people where(each.status="recuperado")) color:color_agentes["recuperado"] marker:false;
				data "Inmunes" value:length(people where(each.status="inmune")) color:color_agentes["inmune"] marker:false;
			}
			overlay position:{10#px,10#px} size:{300#px,100#px} color:#white transparency:0.5{
				draw ""+int(time/86400)+" days, "+mod(time/3600,24)+" hours" color:#white font:font("Arial",36,#bold) at:{20#px,50#px};
			}
		}
	}
}