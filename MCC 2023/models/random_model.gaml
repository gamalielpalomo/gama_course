/**
* Name: Traffic
* Description: define species for traffic simulation
* Author: Patrick Taillandier & Duc Pham
* Tags: driving skill, graph, agent_movement, skill, transport
*/

model simple_traffic_model

global {
	shape_file nodes_shape_file <- shape_file("../includes/gis/new_data/nodes.shp");
	shape_file roads_shape_file <- shape_file("../includes/gis/new_data/roads.shp");
	
	float lane_width <- 3.0;
	
	geometry shape <- envelope(roads_shape_file);
	graph road_network;
	init {
		create intersection from: nodes_shape_file;
		step 			<- 5#seconds;
		starting_date 	<- date("2023-06-23 07:00:00");
		create road from: roads_shape_file {
			// Create another road in the opposite direction
			/*create road {
				num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				maxspeed <- myself.maxspeed;
				linked_road <- myself;
				myself.linked_road <- self;
			}*/
		}
		
		
		road_network <- as_driving_graph(road, intersection);
		
		create vehicle number: 1000 with: (location: one_of(intersection).location);
	}

}

species road skills: [skill_road] {
	rgb color <- #white;
	
	aspect base {
		draw shape color: color end_arrow: 1;
	}
}

species intersection skills: [skill_road_node]{
	aspect default{
		draw sphere(3) at:{location.x,location.y,5} ;
	}
}

species vehicle skills: [advanced_driving] {
	
	map<date,point> agenda_day;	
	point home;
	point next_objective;
	intersection next_objective_int;
	rgb color <- rnd_color(255);
	init {
		home <- any_location_in(world);
		vehicle_length <- 4.0 #m;
		max_speed <- 25 #km / #h;
		max_acceleration <- 3.5;
	}
	
	reflex create_agenda when:(every(#day)) or empty(agenda_day){
		agenda_day <- [];
		int hours_for_activities <- rnd(6,10);
		int sum <- 0;
		int nb_activities <- rnd(6,10);
		int hour_for_go_out <- rnd(7,9);//rnd(7,22-hours_for_activities);
		int hours_per_activity <- int(hours_for_activities/nb_activities);
		date activity_date <- date(current_date.year,current_date.month,current_date.day,hour_for_go_out,rnd(0,59),rnd(0,59));
		loop i from:0 to: nb_activities{ //Number of activities
			activity_date <- activity_date + sum#hours;
			agenda_day <+ (activity_date::any_location_in(world));
			sum <- sum + hours_per_activity;
		}
		
		activity_date <- activity_date + sum#hours;
		agenda_day <+ (activity_date::home);
	}
	reflex update_activity when:not dead(self) and not empty(agenda_day){
		try{
			if after(agenda_day.keys[0]) {
			  	next_objective <-agenda_day.values[0];
				next_objective_int <- intersection closest_to next_objective;
				agenda_day>>first(agenda_day);																															//<-gama-issue14-may08
		 	 }
		}
	 }	
	
	reflex select_next_path when: current_path = nil and next_objective_int {
		// A path that forms a cycle
		do compute_path graph: road_network target: next_objective_int;
	}
	
	reflex commute when: current_path != nil {
		do drive;
	}
	aspect base {
		draw rectangle(vehicle_length, lane_width * num_lanes_occupied) depth:2 color: color rotate: heading border: #black;
		draw triangle(lane_width * num_lanes_occupied) color: #white rotate: heading + 90 border: #black;
	}
}

experiment city type: gui {
	map<int,string> int_to_day <- [1::"Jueves",2::"Viernes",3::"Sábado",4::"Domingo",5::"Lunes",6::"Martes",7::"Miércoles"];
	output synchronized: true {
		display map type: 3d background: #gray {
			species road aspect: base;
			species intersection aspect:default;
			species vehicle aspect: base;	
			overlay size:{0,0} position:{0.1,0.1} transparency:0.5{
				draw "abcdefghiíjklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.:0123456789" at: {0#px,0#px} color:rgb(0,0,0,0) font: font("Arial", 55, #bold);
				int the_day <- current_date.day-starting_date.day +1;
				string str_day <- int_to_day[the_day];
				string minute <- current_date.minute<10?(string(0)+current_date.minute):current_date.minute;
				draw " "+current_date.hour+":"+ minute at:{30#px,30#px} color:#white font: font("Arial", 55,#bold);
			}	
		}
	}
}