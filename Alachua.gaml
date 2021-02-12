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
	date starting_date <- date("2009-05-12-06--00");
	int nb_people <- (247336);
	int nb_latent_init <- 0;
	int nb_infectious_init <- 33;
	int nb_infected_init <- (nb_latent_init+nb_infectious_init);
	int nb_recovered_init <- 0;
	int nb_people_infected <- nb_infected_init update: people count (each.is_infected);
	int nb_people_not_infected <- nb_people - nb_infected_init update: nb_people - nb_people_infected;
	int nb_people_latent <- nb_latent_init update: people count (each.is_latent);
	bool is_latent;
	bool is_infectious;
	bool is_infected;
	bool ever_infected;
	int nb_people_infectious <- nb_infectious_init update: people count (each.is_infectious);
	int nb_people_recovered <- nb_recovered_init update: people count (each.is_recovered);
	int nb_people_ever_infected <- (nb_infected_init + nb_recovered_init) update: people count (each.ever_infected);
	int new_home_infections <-0 update: people count (each.home_infected);
	int new_work_infections<-0 update: people count (each.work_infected); 
	int infection_time;
	int infectious_time;
	float infected_rate update: nb_people_infected/nb_people;
	float ever_infected_rate update: nb_people_ever_infected/nb_people;
	list population_h <- [];
	int index_h;
	int counter_h;
	int counter_nw <-2;
	list population_w <- [];
	int index_w;
	list people_list <- range(0,length(people)-1);
	list s_people_list <- shuffle(people_list);
	int current_index<-0;
	int counter_w<-0;
	agent family_member_1;
	agent family_member_2;
	list family;
	point home_location;
	point work_location;
	point visit_location;
	
	int min_work_start <- 6;
	int max_work_start <- 8;
	int min_work_end <- 16;
	int max_work_end <- 20;
	int visit_time;
	float min_speed <- 400000 #km/#h;
	float max_speed <- 600000 #km/#h;
	int attempt;
	init {
		create large_building from: shape_file_large_buildings {///with: [type::string(read( "the_geom"))] {
				
				color <- #blue;
		}
		///save shape_file("ala_home_2009", nb_people collect each.id);
		create small_building from: shape_file_small_buildings {
				color <- #grey;
		}
		create road from: shape_file_roads;
		///the_graph <- as_edge_graph(road);
		
		list<small_building> residential_buildings <- small_building where (each.color=#grey);
		list<large_building> industrial_buildings <- large_building where (each.color=#blue);
		
		loop i over: home_pops{
					add i to: population_h;
					}
		loop i over: work_pops{
					add i to: population_w;
					}
		loop i over: population_h{
			create people number: (int(i) + (counter_nw*int(i))){
			
			speed <- rnd(min_speed, max_speed);
			start_work <- rnd (min_work_start, max_work_start);
			end_work <- rnd(min_work_end, max_work_end);
			start_visit <- rnd (min_work_start, min_work_end);
			end_visit<- (start_visit+rnd(1,4));
			working_place<-nil;
			living_place <- residential_buildings at index_h;
			
			///working_place <- industrial_buildings at index_w;
			objective <- "resting";
			home_location <- any_location_in (living_place);
			location <- home_location;
			
				
			if counter_h>71106{
				counter_nw<-3;
			}
			}
			index_h<-index_h+1;
			counter_h<-counter_h+int(i);
			}
		write counter_h;
		write index_h;
		write length(people);
		people_list <- range(0,length(people)-1);
		s_people_list <- shuffle(people_list);
		loop i over: population_w{
			loop times: (int(i)){
				///write current_index;
				ask 1 among [(people) at current_index]{
					self.working_place <- industrial_buildings at index_w;
					work_location <- any_location_in (working_place);
					
					}
				///if counter_w<(length(nb_people)-1){
					counter_w<-counter_w+1;
					current_index<-(s_people_list at (counter_w));
					///}
				}
			index_w<- index_w+1;
			}
		ask people{
			if work_location=nil{
				visit_location<-any_location_in (industrial_buildings at rnd(0,2024));
			}
			
		}
		ask nb_latent_init among people {
				is_infected <- true;
				is_infectious <-false;
				is_latent <- true;
				is_recovered <- false;
				ever_infected <- true;
				infection_time <- 0;///rnd(0,575);
		}
		
		ask nb_infectious_init among (people where (ever_infected=false)) {
				is_latent <-false;
				is_infected <- true;
				is_infectious <- true;
				is_recovered <- false;
				ever_infected <- true;
				infectious_time <-0;// rnd(0,1151);
		}
		
		ask nb_recovered_init among (people where (ever_infected=false)){
			is_latent <-false;
			is_infected <- false;
			is_infectious <- false;
			is_recovered<-true;
			ever_infected <- true;
		}
	}
	reflex week_pause when: (cycle/1008)=1 or (cycle/1008)=2 or (cycle/1008)=3 or (cycle/1008)=4 or (cycle/1008)=5 or (cycle/1008)=6 or (cycle/1008)=7 or (cycle/1008)=8 or (cycle/1008)=9{
		save [ever_infected_rate,nb_people_ever_infected,nb_people_latent,nb_people_infectious, nb_people_recovered, new_home_infections, new_work_infections] to: string(cycle)+"_70_2_csvfile.csv" type: "csv" header: true;
	}
	
	reflex end_simulation when: infected_rate=1.0 or cycle/1008=9{
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
	small_building living_place<-nil;
	large_building working_place<-nil;
	point home_location;
	point work_location;
	point visit_location;
	///school_building school_place <- nil;
	///church_building church_place <- nil;
	///health_building health_place <- nil;
	///retirement_building retirement_place <- nil;
	///airport_building airport_place <- nil;
	///jail_building jail_place <- nil;
	int start_work;
	int end_work;
	int start_visit;
	int end_visit;
	string objective;
	point the_target <- nil;
	bool is_infected <- false;
	bool is_latent <- false;
	bool is_infectious <- false;
	bool is_recovered <- false;
	bool ever_infected <- false;
	bool home_infected <- false;
	bool work_infected <-false;
	bool infection_try<-false;
	int infection_time;
	int old_infection_time;
	int infectious_time;
	int old_infectious_time;
	int fam_size;

	rgb color <- #green;
	
	
	reflex move when: the_target != nil {
		do goto target: the_target;
		if (the_target = location) {
			the_target <- nil;
		}
	}
		
	///reflex home_infect when: (is_infectious and the_target=nil and location=home_location){
		///fam_size<-int(sample([2,3],1,true,[(1/3),(2/3)]));
		///ask people at_distance (6) #m{///ask fam_size among (people where ((infection_try=false)) inside self.living_place) { ask people at_distance (6) #m
			///if self.is_infected=false{
				///if flip(0.99) {
					///is_latent <- true;
					///color <- #yellow;
					///is_infected <-true;
					///infection_time <- 0;
				///}
				///self.infection_try<-true;
				///myself.infection_try<-true;
			///}
			///attempt<-attempt+1;
			///write attempt;		
					
			///}
		///}
	reflex h_infect when: (is_infectious) and objective="resting"{
		list closest_3<-(people inside living_place) closest_to(self,3) ;
		ask closest_3 inside self.living_place{
			if the_target=nil{
				if flip(0.0002) {
					if self.ever_infected=false{
						is_latent <- true;
						color <- #yellow;
						is_infected <-true;
						ever_infected <- true;
						home_infected <- true;
						infection_time <- 0;
						write string(self)+ " infected by:" + string(myself) + "at home";
					}
				}			
			}
		}
	}
	reflex w_infect when: (is_infectious) and (objective="working" or objective="visiting"){
		ask 50 among (people inside self.working_place at_distance (6) #m){
			if the_target=nil{
				if flip(0.000070) {
					if self.ever_infected=false{
						is_latent <- true;
						color <- #yellow;
						is_infected <-true;
						ever_infected <- true;
						work_infected <- true;
						infection_time <- 0;
						write string(self)+ " infected by:" + string(myself) + "at work";
					}
				}			
			}
		}
	}
	///reflex work_infect when: (is_infectious and the_target=nil and (location=work_location)){
		///ask people at_distance (6) #m{
			///if flip(0.99) {
				///is_latent <- true;
				///color <- #yellow;
				///is_infected <-true;
				///infection_time <- 0;
				///attempt<-attempt+1;
				///write attempt;
				///}
		///}
	///}
	
	reflex turn_infectious when: is_latent{
		old_infection_time <- infection_time;
		infection_time <- old_infection_time+(1);
		if infection_time=144{
			if flip (0.25) {///((1/144)*3) {
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
			}
		}
		if infection_time=288{
			if flip (0.5) {///((1/144)*3) {
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
		}
		}
		if infection_time=432{
			if flip (0.75) {///((1/144)*3) {
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
		}
		}
		if infection_time=576{
			if flip (1) {///((1/144)*3) {
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
		}
		}
	}
	reflex stop_infectious when: is_infectious{
		old_infectious_time <- infectious_time;
		infectious_time <-old_infectious_time+1;
		if infectious_time=864 {
			if flip (0.33){
				is_infectious <-false;
				is_recovered <- true;
				is_infected <- false;
			}
		}
		if infectious_time=1008 {
			if flip (0.66){
				is_infectious <-false;
				is_recovered <- true;
				is_infected <- false;
			}
		}
		if infectious_time=1152 {
			if flip (1){
				is_infectious <-false;
				is_recovered <- true;
				is_infected <- false;
			}
		}
	}
	///reflex visit_work when: every(11 #mn){
		///if working_place=nil{
		///if flip(0.1){
			///ask 1 among (people where (working_place!=nil)){
				///the_target <- self.work_location;
				///visit_time<-int(current_date.hour);
				
				///}
			///}
		
		///}
		
		///}
	///reflex leave_visit when: working_place=nil and visit_time!=nil{
		///if flip(0.3){
			///the_target <- home_location;
			///visit_time<-nil;
		///}
	///}
	
	reflex time_to_work when: current_date.hour = start_work and objective= "resting" {
		objective <- "working";
		the_target <- work_location;
	}
	reflex time_to_visit when: current_date.hour = start_visit and objective="resting"{
		objective <- "visiting";
		the_target <- visit_location;
	}
	reflex time_to_go_home when: current_date.hour = end_work and objective = "working" {
		objective <- "resting";
		the_target <- home_location;
	}
	reflex time_to_go_home_2 when: current_date.hour = end_visit and objective = "visiting" {
		objective <- "resting";
		the_target <- home_location;
	}
	///reflex reset_infection_try when: every(11 #mn){
		///infection_try<-false;
		///}
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
	parameter "Nb people infected at init" var: nb_infected_init min:1 max: 247336;
	output {
		monitor "Infected people rate" value: infected_rate;
		monitor "Ever infected people rate" value: ever_infected_rate;
		monitor "Total Infections" value: nb_people_ever_infected;
		monitor "Latent" value: nb_people_latent;
		monitor "Infectious" value: nb_people_infectious;
		monitor "Recovered" value: nb_people_recovered;
		monitor "New Home Infections" value: new_home_infections;
		monitor "New Work Infections" value: new_work_infections;
		display city_display type: opengl {
			species large_building aspect: base;
			species small_building aspect: base;
			///species school_building aspect: base;
			species road aspect: geom;
			species people aspect: base;
		}
		
		display chart_display refresh: every(10#cycles) {
			chart "Disease spreading" type: series{
				data "susceptible" value: nb_people_not_infected color: #green;
				data "latent" value: nb_people_latent color: #yellow;
				data "infectious" value: nb_people_infectious color: #purple;
				data "infected" value: nb_people_infected color: #red;
				data "recovered" value: nb_people_recovered color: #black;
				data "ever infected" value: nb_people_ever_infected color: #grey;
			}
		}
	}
}
	