/**
* Name: NewModel
* Based on the internal empty template. 
* Author: servando gomez flore
* Tags: 
*/

model Epidemia

global {
	geometry shape <- square (500);
	map<string,rgb>	color_agentes <- ["susceptible"::#darkcyan, "infectado"::#indianred, "recuperado"::#palegoldenrod, "inmune"::#slategrey];
	float sana_distancia <- 2.0 parameter: "Sana distancia" category: "SIR parameters" min:0.0 max:50.0;
	float beta <- 0.2 parameter: "Beta" category: "SIR parameters" min:0.0 max: 1.0;
	float delta <- 0.2 parameter: "Delta" category:"SIR parameters" min:0.0 max: 1.0;
	init{
		step <- 5#seconds;
		create people number:200;
		ask one_of(people){
			status <- "infectado";
		}
	}
}

species people skills:[moving]{
	string status <- "susceptible" among:["susceptible", "infectado", "recuperado", "inmune"];
	list<people> contactos_de_riesgo <- [] update:people at_distance(sana_distancia);
	float tiempo_infectado <- 0#seconds;
	reflex movimiento{
		do wander;
	}
	reflex infectar_a_otro when:status="infectado"{
		if length(contactos_de_riesgo) > 0{
			ask contactos_de_riesgo {
				if status = "susceptible" and flip(beta){
					status <- "infectado";
				}
			}
		}
	}
	reflex recuperacion when:status="infectado"{
		if tiempo_infectado>2#hours{
		status <- "recuperado";
	}
	else{
		tiempo_infectado <- tiempo_infectado + step;
		}
	}
	reflex recuperado when:status= "recuperado"{
		status <- flip (0.2)?"susceptible":"inmune";
	}
	
	aspect estado_salud{
		draw circle(3) color: color_agentes[status];
		loop contacto over:contactos_de_riesgo{
			draw line(location,contacto.location) color:#white;
		}
	}
}

experiment simulacion type:gui{
	output{
		layout #split;
		display principal type:opengl background: #lightgray{
			species people aspect:estado_salud;
		}
		display graficas type:java2D{
			chart "Epidemia" type:series y_label:"Numero de personas"{
				data "Susceptibles" value:length (people where(each.status="susceptible")) color:color_agentes["susceptible"];
				data "Infectados" value:length (people where(each.status="infectado")) color:color_agentes["infectado"];
				data "Recuperados" value:length (people where(each.status="recuperado")) color:color_agentes["recuperado"];
				data "Inmunes" value:length (people where(each.status="inmune")) color:color_agentes["inmune"];
			}
		}
	}
}