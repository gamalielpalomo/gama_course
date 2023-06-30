/**
* Name: epidemic
* Based on the internal empty template. 
* Author: gamaa
* Tags: 
*/


model epidemic

global{
	
	//epidemic parameters
	int t_infected; //Number of days infected
	int t_latent; //Number of days after a contact to become infected
	
	file roads_shp <- file("../includes/gis/roads.shp");
	file blocks_shp <- file("../includes/gis/blocks_extended.shp");
	
	geometry shape <- envelope(blocks_shp);
	graph roads_network;

	float min_speed <- 1.0 #km / #h;
	float max_speed <- 5.0 #km / #h; 
	float step <- 1#minutes;
	
	
	//HEATMAP
	int size <- 300;
	field instant_heatmap <- field(size, size);
	field history_heatmap <- field(size, size);
	
	
	init{
		t_latent <- 1;
		t_infected <- 2;
		starting_date 	<- date("2023-05-18 06:00:00");
		
		create road from:roads_shp;
		roads_network <- as_edge_graph(road);
		create block from:blocks_shp;
		
		create people number:500;
		ask one_of(people){
			epidemic_status <- "infected";
		}
	}
	reflex update_heatmap {
		instant_heatmap[] <- 0 ;
		ask people {
			instant_heatmap[location] <- instant_heatmap[location] + 10;
			history_heatmap[location] <- history_heatmap[location] + 1;
		}
	}
}
species people skills:[moving]{
	
	string epidemic_status; //"susceptible","exposed","infected","removed"
	list<people> contacts;
	date last_change;
	point my_target;
	point home;
	init{
		epidemic_status <- "susceptible";
		last_change <- current_date;
		speed <- rnd(min_speed, max_speed);
		home <- any_location_in(one_of(block));
		location <- home;
		my_target <- any_location_in(one_of(road));
	}
	reflex movement{
		//location <- point(rnd(100),rnd(100));
		do goto target:my_target on:roads_network;
		if(my_target = location){
			my_target <- any_location_in(one_of(block));
		}
	}
	reflex update_contacts{
		contacts <- people at_distance(2#m);
	}
	reflex spread_epidemic when:contacts!=nil and epidemic_status="infected"{
		ask contacts{
			if self.epidemic_status = "susceptible"{
				self.epidemic_status <- "exposed";
				self.last_change <- current_date;
			}
		}
	}
	reflex udpate_epidemic_status{
		switch epidemic_status{
			match "exposed"{
				if (current_date - self.last_change)/86400  > t_latent{
					self.epidemic_status <- "infected";
					self.last_change <- current_date;
				}
			}
			match "infected"{
				if (current_date - self.last_change)/86400 > t_infected{
					self.epidemic_status <- "removed";
					self.last_change <- current_date;
				}
			}
		}
	}
	aspect default{
		rgb my_color;
		switch epidemic_status{
			match "susceptible"{
				my_color <- #green;
			}
			match "exposed"{
				my_color <- #yellow;
			}
			match "infected"{
				my_color <- #red;
			}
			match "removed"{
				my_color <- #gray;
			}
		}
		draw circle(1) color:my_color;
		draw circle(2) wireframe:true border:#red width:2.0;
	}
}

species road{
	aspect default{
		draw shape color:#white;
	}
}

species block{
	aspect default{
		draw shape color:rgb (162, 136, 230, 255);
	}
}

experiment "epidemic" type:gui {
	map<rgb,string> pollutions <- [#green::"Good",#yellow::"Average",#orange::"Bad",#red::"Hazardous"];
	map<rgb,string> legends <- [#gray::"Buildings",#yellow::"People",rgb(#white)::"Roads"];
	list<rgb> pal <- palette([ #black, #green, #yellow, #orange, #orange, #red, #red, #red]);
	font text <- font("Arial", 14, #bold);
	font title <- font("Arial", 18, #bold);
	output{
		layout #split;
		display main type:opengl background:#black{
			
			overlay position: { 50#px,50#px} size: { 1 #px, 1 #px } background: # black border: #black rounded: false 
            	{
            	//for each possible type, we draw a square with the corresponding color and we write the name of the type
                
                draw "Contact hazard" at: {0, 0} anchor: #top_left  color: #white font: title;
                float y <- 50#px;
                draw rectangle(40#px, 160#px) at: {20#px, y + 60#px} wireframe: true color: #white;
             
                loop p over: reverse(pollutions.pairs)
                {
                    draw square(40#px) at: { 20#px, y } color: rgb(p.key, 0.6) ;
                    draw p.value at: { 60#px, y} anchor: #left_center color: # white font: text;
                    y <- y + 40#px;
                }
                
                y <- y + 40#px;
                draw "Legend" at: {0, y} anchor: #top_left  color: #white font: title;
                y <- y + 50#px;
                draw rectangle(40#px, 120#px) at: {20#px, y + 40#px} wireframe: true color: #white;
                loop p over: legends.pairs
                {
                    draw square(40#px) at: { 20#px, y } color: rgb(p.key, 0.8) ;
                    draw p.value at: { 60#px, y} anchor: #left_center color: # white font: text;
                    y <- y + 40#px;
                }
            }
			
			mesh instant_heatmap scale: 1 color: pal smooth: 2 ;
			species road aspect:default;
			species block aspect:default;
			species people aspect:default;
			
			//mesh history_heatmap scale: 0.01 color: gradient([#black::0, #cyan::0.5, #red::1]) transparency: 0.2 position: {0, 0, 0.001} smooth:1 ;
			
		}
		display plot type:java2D{
			chart name:"epidemic evolution" type:pie{
				data "infected" value:length(people where(each.epidemic_status="infected")) marker:false style:area color:#red;
				data "susceptible" value:length(people where(each.epidemic_status="susceptible")) marker:false style:area color:#green;
				data "removed" value:length(people where(each.epidemic_status="removed")) marker:false style:area color:#gray;
				data "exposed" value:length(people where(each.epidemic_status="exposed")) marker:false style:area color:#yellow;
			}
		}
	}
}