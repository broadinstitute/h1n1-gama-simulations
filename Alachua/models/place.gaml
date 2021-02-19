/**
* Name: Alachua
* Based on the internal empty template. 
* Author: nchri
* Tags: 
*/


model Alachua

global {
	file shape_file_large_buildings <- file("../includes/ala_work_2009.shp");
	file shape_file_small_buildings <- file("../includes/ala_home_2009.shp");
	file home_pops <- csv_file("../includes/try1.csv");
	file work_pops <- csv_file("../includes/try2.csv");
	file shape_file_roads <- file("../includes/tl_2017_12001_roads.shp");
	file shape_file_bounds <- file("../includes/Alachua_Clean.shp");
	geometry shape <- envelope(shape_file_roads);
	float step <- 10 #mn;
	date starting_date <- date("2009-04-01-06--00");
	int nb_people <- (2409000/10);
	int nb_infected_init <- 5;
	int nb_latent_init <- 5;
	int nb_infectious_init <- 5;
	int nb_people_infected <- nb_infected_init update: people count (each.is_infected);
	int nb_people_not_infected <- nb_people - nb_infected_init update: nb_people - nb_people_infected;
	int nb_people_latent <- nb_latent_init update: people count (each.is_latent);
	int nb_people_infectious <- nb_infectious_init update: people count (each.is_infectious);
	float infected_rate update: nb_people_infected/nb_people;
	list population_h <- [];
	int index_h;
	list population_w <- [];
	int index_w;
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16;
	int max_work_end <- 20;
	float min_speed <- 40 #km/#h;
	float max_speed <- 60 #km/#h;
	graph the_graph;
	
	
	init {
		create large_building from: shape_file_large_buildings {///with: [type::string(read( "the_geom"))] {
				
				color <- #blue;
		}
		///save shape_file("ala_home_2009", nb_people collect each.id);
		create small_building from: shape_file_small_buildings {
				color <- #grey;
		}
		create road from: shape_file_roads;
		the_graph <- as_edge_graph(road);
		
		list<small_building> residential_buildings <- small_building where (each.color=#grey);
		list<large_building> industrial_buildings <- large_building where (each.color=#blue);
		
		loop i over: home_pops{
					add i to: population_h;
					}
		loop i over: work_pops{
					add i to: population_w;
					}
		loop i over: population_h{
			create people number: i {
			
			speed <- rnd(min_speed, max_speed);
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			working_place<-nil;
			living_place <- residential_buildings at index_h;
			
			///working_place <- industrial_buildings at index_w;
			objective <- "resting";
			location <- any_location_in (living_place);
			}
			index_h<-index_h+1;
			}
		loop i over: population_w{
			ask (int(i)) among people{
				working_place <- industrial_buildings at index_w;
			}
			index_w<- index_w+1;
			}
		ask nb_infected_init among people {
				is_infected <- true;
		}
	}
	reflex end_simulation when: infected_rate=1.0{
		do pause;
	}
}

species large_building {
	rgb color <- #gray;
	
	aspect base {
		draw shape color: color;
	}
}

species small_building {
	rgb color <- #gray;
	
	aspect base {
		draw shape color: color;
	}
}

species road {
	rgb color <- #black;
	aspect geom {
		draw shape color: color;
	}
}

species people skills: [moving]{
	small_building living_place <- nil;
	large_building working_place <- nil;
	int start_work;
	int end_work;
	string objective;
	point the_target <- nil;
	bool is_infected <- false;
	bool is_latent <- false;
	bool is_infectious <- false;
	rgb color <- #green;
	
	reflex move when: the_target != nil {
		do goto target: the_target on: the_graph;
		if (the_target = location) {
			the_target <- nil;
		}
	}
		
	reflex infect when: is_infectious{
		ask people at_distance (6) #m{
			if flip(0.1) {
				is_latent <- true;
				color <- #yellow;
				is_infected <-true;
			}
		}
	}
	
	reflex turn_infectious when: is_infected{
		if flip((1/144)*3) {
			is_infectious <- true;
			is_latent <- false;
		}
		
	}
	reflex time_to_work when: current_date.hour = start_work and objective= "resting" {
		objective <- "working";
		the_target <- any_location_in (working_place);
	}
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working" {
		objective <- "resting";
		the_target <- any_location_in (living_place);
	}
	
	aspect base {
		draw circle(1) color: is_infectious ? #red: color border: #black;
	}
}
experiment Alachua type:gui{
	parameter "Shapefile for large buildings:" var: shape_file_large_buildings category: "GIS" ;
	parameter "Shapefile for small buildings:" var: shape_file_small_buildings category: "GIS" ;
	parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Nb people infected at init" var: nb_infected_init min:1 max: 2409000;
	output {
		monitor "Infected people rate" value: infected_rate;
		display city_display type: opengl {
			species large_building aspect: base;
			species small_building aspect: base;
			species road aspect: geom;
			species people aspect: base;
		}
		
		display chart_display refresh: every(10#cycles) {
			chart "Disease spreading" type: series{
				data "susceptible" value: nb_people_not_infected color: #green;
				data "latent" value: nb_people_latent color: #yellow;
				data "infectious" value: nb_people_infectious color: #purple;
				data "infected" value: nb_people_infected color: #red;
			}
		}
	}
}

