/***
* Name: modelo1
* Author: gamaa
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model modelo_ejemplo_sesion2

global torus:false{
	geometry shape <- square(1000);
	float step <- 1#m;
	
	init{
		starting_date <- date([2020,7,9,18,0,0]);
		create persona number:100;
	}
	reflex main{
		write current_date;
	}
}

species persona skills:[moving]{
	list<float> edades_de_mis_amigos <- [8.3, 9.5, 3.2];
	float edad <- 0.0;
	string genero <- "mujer";
	int cantidad_hijos <- 2;
	float dinero_en_el_banco <- 2320.5;
	bool estudia <- true;
	
	
	reflex principal when:mod(cycle,20)=0{
		//write edades_de_mis_amigos[0];
		loop times:3{
		}
		if (edad < 50){
			edad <- edad + 1;
		}
		else{
			edad <- edad + 0.5;
		}
		estudia <- true and estudia;
		do mi_funcion_de_movimiento;		
		write name;
	}
	
	action mi_funcion_de_movimiento{
		do wander;
	}
	
	aspect basico{
		draw square(50) color:rgb(edad,255-edad,0);
	}
	aspect circulo{
		draw circle(50) color:rgb(edad,255-edad,0);
	}
}

experiment primer_experimento type:gui{
	output{
		display pantalla_principal type:opengl{
			species persona aspect:circulo;
		}
	}
}