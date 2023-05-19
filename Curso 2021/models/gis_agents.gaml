/***
* Name: gisagents
* Author: gamaa
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model gisagents

/* Insert your model definition here */
global{
	file calles <- file("../includes/small_roads.shp");
	file archivo_manzanas <- file("../includes/blocks.shp");
	geometry shape <- envelope(calles);
	list<people> jovenes;//10-30
	list<people> adultos;//31-60
	list<people> mayores;//>60
	int numero_interacciones <- 0 update:length(people where(length(each.interacciones)>0));
	graph red_de_calles;
	init{
		numero_interacciones <- 0;
		create calle from:calles;
		create block from:archivo_manzanas;
		create people number:200;
		red_de_calles <- as_edge_graph(calle);
		jovenes <- people where(each.age>10 and each.age <=30);
		adultos <- people where(each.age>30 and each.age <60);
		mayores <- people where(each.age>60);
	}
}

species people skills:[moving]{
	int age;
	rgb color_agente;
	list<people> encuentros;
	list<people> interacciones;
	point objetivo <- any_location_in(one_of(calle));
	init{
		encuentros <- [];
		age <- rnd(70)+10;
		location <- any_location_in(one_of(calle));
		if age>10 and age<=30{//Soy del grupo de jovenes
			color_agente <- rgb(255,0,0);
		}
		else if age>30 and age<=60{
			color_agente <- #blue;//Soy del grupo de adultos
		}
		else{
			color_agente <- #green;//Soy del grupo de mayores
		}
	}
	reflex main{
		if objetivo = location{//Ya llegué
			objetivo <- any_location_in(one_of(calle));
		}
		do goto target:objetivo on:red_de_calles;
		encuentros <- people at_distance(50);
		if age>10 and age<=30{
			interacciones <- encuentros where(each.age>10 and each.age<=30);
		}
		else if age>30 and age<=60{
			interacciones <- encuentros where(each.age>30 and each.age<=60);
		}
		else{
			interacciones <- encuentros where(each.age>60);
		}
		save [current_date,name,length(interacciones)] to: "../results/agentes_interacciones.csv" type:"csv" rewrite: false;
	}
	aspect basico{
		draw circle(4#m) color:color_agente;
		loop agente over:interacciones{
			draw line(location,agente.location) color:color_agente;
		}
		/*if age>10 and age<=30{
			loop agente over:jovenes{
				draw line(location,agente.location) color:#red;
			}
		}
		else if age>30 and age<=60{
			loop agente over:adultos{
				draw line(location,agente.location) color:#blue;
			}
		}
		else{
			loop agente over:mayores{
				draw line(location,agente.location) color:#green;
			}
		}*/
	}
}

species calle{
	aspect basico{
		draw shape color:#white;
	}
}

species block{
	aspect basico{
		draw shape color:rgb (26, 82, 119,80);
	}
}

experiment mi_experimento type:gui{
	output{
		layout #split;
		display principal type:opengl{
			//species calle aspect:basico;
			species block aspect:basico;
			species people aspect:basico;
		}
		display grafica type:java2D{
			chart "Interacciones" type:series{
				data "Interacciones" value:numero_interacciones;
			}
		}
	}
}