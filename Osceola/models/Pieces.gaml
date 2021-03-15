/**
* Name: Pieces
* Based on the internal empty template. 
* Author: nchri
* Tags: 
*/


model Pieces

/* Insert your model definition here */

int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16;
	int max_work_end <- 20;
	float min_speed <- 10000000 #km/#h;
	float max_speed <- 20000000 #km/#h;
create people number: nb_people {
			speed <- rnd(min_speed, max_speed);
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			living_place <- one_of(residential_buildings);
			working_place <- one_of(industrial_buildings);
			objective <- "resting";
			location <- any_location_in (living_place);
			}
species people skills: [moving]{
	rgb color <- #yellow;
	small_building living_place <- nil;
	large_building working_place <- nil;
	int start_work;
	int end_work;
	string objective;
	point the_target <- nil;
	
	reflex time_to_work when: current_date.hour = start_work and objective= "resting" {
		objective <- "working";
		the_target <- any_location_in (working_place);
	}
	
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working" {
		objective <- "resting";
		the_target <- any_location_in (living_place);
	}
	
	reflex move when: the_target != nil {
		do goto target: the_target on: the_graph;
		if the_target = location {
			the_target <- nil;
		}
	}
	aspect base {
		draw circle(4) color: color border: #black;
	}
}

experiment MiamiDade type:gui {
	parameter "Shapefile for the large buildings:" var: shape_file_large_buildings category: "GIS";
	parameter "Shapefile for the small buildings:" var: shape_file_small_buildings category: "GIS";
	parameter "Shapefile for the roads" var: shape_file_roads category: "GIS";
	parameter "Shapefile for the bounds" var: shape_file_bounds category: "GIS";
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Earliest hour to start work" var: min_work_start category: "People" min: 2 max: 8;
	parameter "Latest hour to start work" var: max_work_start category: "People" min: 8 max: 12;
	parameter "Earliest hour to end work" var: min_work_end category: "People" min: 12 max: 16;
	parameter "Latest hour to end work" var: max_work_end category: "People" min: 16 max: 23;
	parameter "minimal speed" var: min_speed category: "People" min: 400000000 #km/#h;
	parameter "maximal speed" var: max_speed category: "People" max: 2000000000 #km/#h;
	
	output {
		display city_display type: opengl {
			species large_building aspect: base;
			species small_building aspect: base;
			species road aspect: geom;
			species people aspect: base;
		}
		display chart_display refresh: every(10#cycles) {
			chart "People Objectif" type: pie style: exploded size: {1, 0.5} position: {0, 0} {
				data "Working" value: people count (each.objective="working") color: #magenta;
				data "Resting" value: people count (each.objective="resting") color: #blue;
			}
		}
	}
}