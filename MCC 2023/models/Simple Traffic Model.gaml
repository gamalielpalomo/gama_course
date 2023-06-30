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
	
	geometry shape <- envelope(roads_shape_file);
	graph road_network;
	init {
		create intersection from: nodes_shape_file;
		
		create road from: roads_shape_file {
			// Create another road in the opposite direction
			create road {
				num_lanes <- myself.num_lanes;
				shape <- polyline(reverse(myself.shape.points));
				maxspeed <- myself.maxspeed;
				linked_road <- myself;
				myself.linked_road <- self;
			}
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

//intersection species
species intersection skills: [skill_road_node] {
	bool is_traffic_signal;
	float time_to_change <- 60#s ;
	float counter <- rnd(time_to_change);
	
	//take into consideration the roads coming from both direction (for traffic light)
	list<road> ways1;
	list<road> ways2;
	
	//if the traffic light is green
	bool is_green;
	rgb color <- #yellow;

	//initialize the traffic light
	action initialize {
		do compute_crossing;
		stop << [];
		if (flip(0.5)) {
			do to_green;
		} else {
			do to_red;
		}
	}

	action compute_crossing {
		if (length(roads_in) >= 2) {
			road rd0 <- road(roads_in[0]);
			list<point> pts <- rd0.shape.points;
			float ref_angle <- last(pts) direction_to rd0.location;
			loop rd over: roads_in {
				list<point> pts2 <- road(rd).shape.points;
				float angle_dest <- last(pts2) direction_to rd.location;
				float ang <- abs(angle_dest - ref_angle);
				if (ang > 45 and ang < 135) or (ang > 225 and ang < 315) {
					ways2 << road(rd);
				}
			}
		}

		loop rd over: roads_in {
			if not (rd in ways2) {
				ways1 << road(rd);
			}
		}
	}

	//shift the traffic light to green
	action to_green {
		stop[0] <- ways2;
		color <- #green;
		is_green <- true;
	}

	//shift the traffic light to red
	action to_red {
		stop[0] <- ways1;
		color <- #red;
		is_green <- false;
	}

	//update the state of the traffic light
	reflex dynamic_node when: is_traffic_signal {
		counter <- counter + step;
		if (counter >= time_to_change) {
			counter <- 0.0;
			if is_green {
				do to_red;
			} else {
				do to_green;
			}
		}
	}

	aspect base {
		draw circle(5) color: color;
	}
}

species vehicle skills: [advanced_driving] {
	rgb color <- rnd_color(255);
	init {
		vehicle_length <- 1.9 #m;
		max_speed <- 100 #km / #h;
		max_acceleration <- 3.5;
	}

	reflex select_next_path when: current_path = nil {
		// A path that forms a cycle
		do compute_path graph: road_network target: one_of(intersection);
	}
	
	reflex commute when: current_path != nil {
		do drive;
	}
	aspect base {
		draw triangle(5.0) color: color rotate: heading + 90 border: #black;
	}
}

experiment city type: gui {
	output synchronized: true {
		display map type: 3d background: #gray {
			species road aspect: base;
			species vehicle aspect: base;		}
	}
}