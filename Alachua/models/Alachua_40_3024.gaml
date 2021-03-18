/**
* Name: Alachua
* Based on the internal empty template. 
* Author: nchri
* Tags: 
*/

model Alachua

global {
	file shape_file_home_buildings <- file("../includes/ala_home_2009.shp"); //residential building shapefile with points as 5 meter squares
	file shape_file_work_buildings <- file("../includes/ala_work_2009.shp"); //workplace building shapefile shapefile with points as 5 meter squares
	file home_pops <- csv_file("../includes/ala_home_data.csv"); //the number of jobs represented in each residential building
	file work_pops <- csv_file("../includes/ala_work_data.csv"); //the number of jobs represented in each workplace building
	file shape_file_roads <- file("../includes/tl_2017_12001_roads.shp"); 
	file shape_file_bounds <- file("../includes/Alachua_Clean.shp");
	geometry shape <- envelope(shape_file_roads);
	float step <- 10 #mn;
	date starting_date <- date("2009-05-12-06--00"); //for Alachua specifically, the cases go up from the 1 reported (33 in the model) after this date
	int nb_people <- (247336); //Alachua population size
	int nb_latent_init <- 0;
	int nb_infectious_init <- 33; //initial number of cases (assumed all infectious, but this may not be true)
	int nb_infected_init <- (nb_latent_init+nb_infectious_init);
	int nb_recovered_init <- 0; //assume no recovered
	int nb_people_infected <- nb_infected_init update: people count (each.is_infected);
	int nb_people_not_infected <- nb_people - nb_infected_init update: nb_people - nb_people_infected;
	int nb_people_latent <- nb_latent_init update: people count (each.is_latent);
	bool is_latent; 
	bool is_infectious;
	bool is_infected;
	bool ever_infected; //tracks number of infections overall without regard to stage of infection
	int nb_people_infectious <- nb_infectious_init update: people count (each.is_infectious); //tracker for the monitor
	int nb_people_recovered <- nb_recovered_init update: people count (each.is_recovered); //tracker for the monitor
	int nb_people_ever_infected <- (nb_infected_init + nb_recovered_init) update: people count (each.ever_infected); //tracker for the monitor
	int new_home_infections <-0 update: people count (each.home_infected); //keeps track of how many infections are the result of infections within the household
	int new_work_infections<-0 update: people count (each.work_infected);  //keeps track of how many infections are the result of infections within the workplace
	int infection_time; 
	int infectious_time;
	float infected_rate update: nb_people_infected/nb_people; //tracker for the monitor
	float ever_infected_rate update: nb_people_ever_infected/nb_people; //tracker for the monitor
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
	
	point home_location; //an agent's assigned household
	point work_location; //an agent's assigned workplace
	point visit_location; //an agent's assigned workplace to go to when they don't have a workplace
	
	int min_work_start <- 6; 
	int max_work_start <- 8;
	int min_work_end <- 16;
	int max_work_end <- 20;
	int visit_time;
	float min_speed <- 400000 #km/#h; //commute speed doesn't really matter here (pretty much instant)
	float max_speed <- 600000 #km/#h;
	
	float w_infect_param<-0.000066125;
	
	int sah_counter<-0;
	bool sah_complete<-false;
	//list family;
	bool rh_complete<-false;
	list hundred_list<-[];
	
	init {
		create large_building from: shape_file_work_buildings {///with: [type::string(read( "the_geom"))] {
				
				color <- #blue;
		}
		///save shape_file("ala_home_2009", nb_people collect each.id);
		create small_building from: shape_file_home_buildings {
				color <- #grey;
		}
		create road from: shape_file_roads;
		///the_graph <- as_edge_graph(road);
		
		list<small_building> residential_buildings <- small_building where (each.color=#grey); //list of homes
		list<large_building> industrial_buildings <- large_building where (each.color=#blue); //list of workplaces
		
		loop i over: home_pops{ //over the csv, loop to add the number of jobs represented for each residential building as an entry in a list
					add i to: population_h;
					}
		loop i over: work_pops{ //over the csv, loop to add the number of jobs represneted for each workplace as an entry in a list
					add i to: population_w;
					}
		loop i over: population_h{ //for every job represented in a residential building, create that many agents of the species "people" 
			create people number: (int(i) + (counter_nw*int(i))){ //plus the appropriate number of agents not represented by jobs in the residential building to equal the population of Alachua county
			//for each person represented by a job in the residential buildings, there are 2.1069 that are not
			//create 2 extra people agents for most of the list, and eventually increase to 3 extra people agents so that an average of 2.1069 are added
			speed <- rnd(min_speed, max_speed); //speed is irrelevant
			start_work <- rnd (min_work_start, max_work_start); //gives each agent a time to start work
			end_work <- rnd(min_work_end, max_work_end); //gives each agent a time to end work
			start_visit <- rnd (min_work_start, min_work_end); //gives each agent a time to start a visit
			end_visit<- (start_visit+rnd(1,4)); //gives each agent a time to end a visit (after at least an hour there)
			working_place<-nil; //wait to assign working place
			living_place <- residential_buildings at index_h; //an agent's home is an attribute so that that is returns to the same one each time
			
			objective <- "resting"; //people at home are resting at when they aren't working, giving the cue for certain reflexes
			home_location <- any_location_in (living_place); //the actual location within the square of their home
			location <- home_location; //the start at their home location
			
				
			if counter_h>71106{ //changes the number of extra agents added for one agent represented by a job in the home csv
				counter_nw<-3;
			}
			}
			index_h<-index_h+1; //moves to the next spot on the list of residential buildings
			counter_h<-counter_h+int(i); //keeps track of how many people agents have been added that are represented by a job in the home csv
			}
		write counter_h; //check that the number of jobs created is 79618
		write index_h; //check that the number of residential buildings is 4263
		write length(people); //should be roughly 247366, the decimal 2.1069 and the grouping of "jobbed" and "extra" agents keep it from being exact
		people_list <- range(0,length(people)-1); //list of the people created
		s_people_list <- shuffle(people_list); //shuffle people list so that those assigned their residences last aren't those without workplaces (lowering spread for them)
		loop i over: population_w{ //for every job represented in a workplace building
			loop times: (int(i)){
				ask 1 among [(people) at current_index]{ //choose 1 person from the shuffled list to have that workplace 
					self.working_place <- industrial_buildings at index_w;
					work_location <- any_location_in (working_place);
					
					}
				
					counter_w<-counter_w+1; //move to the next position in the shuffled list
					current_index<-(s_people_list at (counter_w)); //set the index at which the next person will be chosen from
				}
			index_w<- index_w+1;
			}
		ask people{
			if work_location=nil{ //those without a workplace gain a visit location that they can go to (any workplace)
				visit_location<-any_location_in (industrial_buildings at rnd(0,2024));
			}
			
		}
		ask nb_latent_init among people { //establishes behavior of the agents that are latent at the beginning
				is_infected <- true;
				is_infectious <-false;
				is_latent <- true;
				is_recovered <- false;
				ever_infected <- true;
				infection_time <- 0;///rnd(0,575);
		}
		
		ask nb_infectious_init among (people where (ever_infected=false)) { //establishes behavior of the agents that are infectious at the beginning (makes sure not to choose one of the agents already selected to be latent)
				is_latent <-false;
				is_infected <- true;
				is_infectious <- true;
				is_recovered <- false;
				ever_infected <- true;
				infectious_time <-0;// rnd(0,1151);
				//those infectious at the start should be assigned families that they can infect
				family<-(people inside living_place) closest_to(self,3); //family is the closest 3 agents in one's home; in list
						family1<-string(family at 0); //first member of family list as a string
						family1<- replace(family1,'p',''); //removes all of the string except the index number
						family1<- replace(family1,'e','');
						family1<- replace(family1,'o','');
						family1<- replace(family1,'l','');
						family1<- replace(family1,'(','');
						family1<- replace(family1,')','');
						family1_i<-int(family1); //turn the index number into an integer
		
						if length(family)>=2{ //if there are two members of the family
							family2<-string(family at 1); //second member of family list as a string
							family2<- replace(family2,'p','');
							family2<- replace(family2,'e','');
							family2<- replace(family2,'o','');
							family2<- replace(family2,'l','');
							family2<- replace(family2,'(','');
							family2<- replace(family2,')','');
							family2_i<-int(family2);
							}
		
						if length(family)>=3{//if there are three members of the family
							family3<-string(family at 2); //second member of family list as a string
							family3<- replace(family3,'p','');
							family3<- replace(family3,'e','');
							family3<- replace(family3,'o','');
							family3<- replace(family3,'l','');
							family3<- replace(family3,'(','');
							family3<- replace(family3,')','');
							family3_i<-int(family3);
							
							}
						write self; //write the name of the agents that are initially infected to check they have been assigned families
		}
		
		ask nb_recovered_init among (people where (ever_infected=false)){ //establishes behavior of the agents that are recovered at the beginning (makes sure not to choose one of the agents already selected to be latent or infectious)
			is_latent <-false;
			is_infected <- false;
			is_infectious <- false;
			is_recovered<-true;
			ever_infected <- true;
		}
	}
		
	///reflex week_pause when: (cycle/1008)=1 or (cycle/1008)=2 or (cycle/1008)=3 or (cycle/1008)=4 or (cycle/1008)=5 or (cycle/1008)=6 or (cycle/1008)=7 or (cycle/1008)=8 or (cycle/1008)=9 or (cycle/1008)=10 or (cycle/1008)=11 or (cycle/1008)=12{
		///save [ever_infected_rate,nb_people_ever_infected,nb_people_latent,nb_people_infectious, nb_people_recovered, new_home_infections, new_work_infections] to: string(cycle)+"_25_csvfile.csv" type: "csv" header: true;
	///} //saves some key stats after the simulation has run for a week (through 12 weeks)
	
	///reflex end_simulation when: infected_rate=1.0 or cycle/1008=12 or (nb_people_infectious+nb_people_latent)=0{
		///save [ever_infected_rate,nb_people_ever_infected,nb_people_latent,nb_people_infectious, nb_people_recovered, new_home_infections, new_work_infections] to: string(cycle)+"_25_csvfile.csv" type: "csv" header: true;
	 //saves some key stats after the simulation has run finished
		//do pause;
	//} //stops the simulation is everyone is infected or after 12 weeks
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
	list people_list;
	small_building living_place<-nil;
	large_building working_place<-nil;
	point home_location;
	point work_location;
	point visit_location;
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
	int infection_time;
	int old_infection_time;
	int infectious_time;
	int old_infectious_time;
	list family;
	string family1; //to be assigned when an agent is infected
	string family2; //to be assigned when an agent is infected
	string family3; //to be assigned when an agent is infected
	int family1_i; //to be assigned when an agent is infected
	int family2_i; //to be assigned when an agent is infected
	int family3_i; //to be assigned when an agent is infected
	int fam_size; //can be more precise on the average family size of 2.6 (needs to be implemented)
	bool w_to_h <- false; //marker to show if an agent infected at work needs to be assigned a family
	bool stay_at_home <-false;
	
	
	///float w_infect_param <- 0.00006125;

	rgb color <- #green;
	
	
	reflex move when: the_target != nil {
		do goto target: the_target;
		if (the_target = location) { 
			the_target <- nil;
		}
	}
		
	reflex h_infect when: (is_infectious) and objective="resting"{ //for those who are infectious and in the home
		// when one is infected at home, give it a family
		if length(family)>=1{
		ask people at family1_i {
			if objective="resting"{ //only if the agent to be infected has stopped and is not just passing by outside
				if flip(0.0002) { //parameter of infectivity based on case study (produces roughly 10 home infections from an intial population of 33, which is around 30%)
					if self.ever_infected=false{ //can only infect those not already infected
						is_latent <- true; //if infected, make them latent
						color <- #yellow;
						is_infected <-true;
						ever_infected <- true;
						home_infected <- true; //so we know they were infected at hom
						infection_time <- 0; //set infection time at 0 so that the infected agent can become infectious at the appropriate time
						family<-(people inside living_place) closest_to(self,3);
						family1<-string(family at 0);
						family1<- replace(family1,'p','');
						family1<- replace(family1,'e','');
						family1<- replace(family1,'o','');
						family1<- replace(family1,'l','');
						family1<- replace(family1,'(','');
						family1<- replace(family1,')','');
						family1_i<-int(family1);
		
						if length(family)>=2{
							family2<-string(family at 1);
							family2<- replace(family2,'p','');
							family2<- replace(family2,'e','');
							family2<- replace(family2,'o','');
							family2<- replace(family2,'l','');
							family2<- replace(family2,'(','');
							family2<- replace(family2,')','');
							family2_i<-int(family2);
							}
		
						if length(family)>=3{
							family3<-string(family at 2);
							family3<- replace(family3,'p','');
							family3<- replace(family3,'e','');
							family3<- replace(family3,'o','');
							family3<- replace(family3,'l','');
							family3<- replace(family3,'(','');
							family3<- replace(family3,')','');
							family3_i<-int(family3);
							
							}
						//write family;
						write string(self)+ " infected by:" + string(myself) + "at home in cycle " +string(cycle); //so we know who they were infected by
					}
				}			
			}
		}
		
		}
		if length(family)>=2{
		ask people at family2_i {
			if objective="resting"{ //only if the agent to be infected has stopped and is not just passing by outside
				if flip(0.0002) { //parameter of infectivity based on case study (produces roughly 10 home infections from an intial population of 33, which is around 30%)
					if self.ever_infected=false{ //can only infect those not already infected
						is_latent <- true; //if infected, make them latent
						color <- #yellow;
						is_infected <-true;
						ever_infected <- true;
						home_infected <- true; //so we know they were infected at hom
						infection_time <- 0; //set infection time at 0 so that the infected agent can become infectious at the appropriate time
						family<-(people inside living_place) closest_to(self,3);
						family1<-string(family at 0);
						family1<- replace(family1,'p','');
						family1<- replace(family1,'e','');
						family1<- replace(family1,'o','');
						family1<- replace(family1,'l','');
						family1<- replace(family1,'(','');
						family1<- replace(family1,')','');
						family1_i<-int(family1);
		
						if length(family)>=2{
							family2<-string(family at 1);
							family2<- replace(family2,'p','');
							family2<- replace(family2,'e','');
							family2<- replace(family2,'o','');
							family2<- replace(family2,'l','');
							family2<- replace(family2,'(','');
							family2<- replace(family2,')','');
							family2_i<-int(family2);
							}
		
						if length(family)>=3{
							family3<-string(family at 2);
							family3<- replace(family3,'p','');
							family3<- replace(family3,'e','');
							family3<- replace(family3,'o','');
							family3<- replace(family3,'l','');
							family3<- replace(family3,'(','');
							family3<- replace(family3,')','');
							family3_i<-int(family3);
							
							}
						//write family;
						write string(self)+ " infected by:" + string(myself) + "at home in cycle " +string(cycle); //so we know who they were infected by
					}
				}			
			}
		}
	}
	
	if length(family)=3{
		ask people at family3_i{
			if objective="resting"{ //only if the agent to be infected has stopped and is not just passing by outside
				if flip(0.0002) { //parameter of infectivity based on case study (produces roughly 10 home infections from an intial population of 33, which is around 30%)
					if self.ever_infected=false{ //can only infect those not already infected
						is_latent <- true; //if infected, make them latent
						color <- #yellow;
						is_infected <-true;
						ever_infected <- true;
						home_infected <- true; //so we know they were infected at hom
						infection_time <- 0; //set infection time at 0 so that the infected agent can become infectious at the appropriate time
						family<-(people inside living_place) closest_to(self,3);
						family1<-string(family at 0);
						family1<- replace(family1,'p','');
						family1<- replace(family1,'e','');
						family1<- replace(family1,'o','');
						family1<- replace(family1,'l','');
						family1<- replace(family1,'(','');
						family1<- replace(family1,')','');
						family1_i<-int(family1);
		
						if length(family)>=2{
							family2<-string(family at 1);
							family2<- replace(family2,'p','');
							family2<- replace(family2,'e','');
							family2<- replace(family2,'o','');
							family2<- replace(family2,'l','');
							family2<- replace(family2,'(','');
							family2<- replace(family2,')','');
							family2_i<-int(family2);
							}
		
						if length(family)>=3{
							family3<-string(family at 2);
							family3<- replace(family3,'p','');
							family3<- replace(family3,'e','');
							family3<- replace(family3,'o','');
							family3<- replace(family3,'l','');
							family3<- replace(family3,'(','');
							family3<- replace(family3,')','');
							family3_i<-int(family3);
							
							}
						//write family;
						write string(self)+ " infected by:" + string(myself) + "at home in cycle " +string(cycle); //so we know who they were infected by
					}
				}			
			}
		}
	}
	
	}
	
	
	reflex w_infect when: (is_infectious) and (objective="working" or objective="visiting"){ //for those infectious and at work
		ask 50 among (people inside self.working_place){ //at_distance (6) #m){ //to simulate a workplace of limited size, agents can only infect 50 of the agents that share their workplace
			if the_target=nil{
				if flip(w_infect_param) { //parameter of infectivity based on experimentation
					if self.ever_infected=false{
						is_latent <- true;
						color <- #yellow;
						is_infected <-true;
						ever_infected <- true;
						work_infected <- true;
						infection_time <- 0;
						w_to_h <- true; //set true so the next time an agent goes home, it will define its family
						write string(self)+ " infected by:" + string(myself) + "at work in cycle "+string(cycle);
					}
				}			
			}
		}
	}
	
	reflex w_to_h when: w_to_h=true and objective="resting"{
		// for those infected at work to define their family
		family<-(people inside living_place) closest_to(self,3);
						family1<-string(family at 0);
						family1<- replace(family1,'p','');
						family1<- replace(family1,'e','');
						family1<- replace(family1,'o','');
						family1<- replace(family1,'l','');
						family1<- replace(family1,'(','');
						family1<- replace(family1,')','');
						family1_i<-int(family1);
		
						if length(family)>=2{
							family2<-string(family at 1);
							family2<- replace(family2,'p','');
							family2<- replace(family2,'e','');
							family2<- replace(family2,'o','');
							family2<- replace(family2,'l','');
							family2<- replace(family2,'(','');
							family2<- replace(family2,')','');
							family2_i<-int(family2);
							}
		
						if length(family)>=3{
							family3<-string(family at 2);
							family3<- replace(family3,'p','');
							family3<- replace(family3,'e','');
							family3<- replace(family3,'o','');
							family3<- replace(family3,'l','');
							family3<- replace(family3,'(','');
							family3<- replace(family3,')','');
							family3_i<-int(family3);
							}
							w_to_h<-false;
	}
	
	reflex turn_infectious when: is_latent{
		old_infection_time <- infection_time; //increase the time one has been infected by one hour
		infection_time <- old_infection_time+(1);
		if infection_time=144{ //based on literature, can become infectious at 24 hours post exposure
			if flip (0.25) { 
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
			}
		}
		if infection_time=288{
			if flip (0.5) { //based on literature, can become infectious at 48 hours post exposure (if not already infectious, the chances of becoming infectious increase over time)
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
		}
		}
		if infection_time=432{
			if flip (0.75) { //based on literature, can become infectious at 72 hours post exposure
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
		}
		}
		if infection_time=576{
			if flip (1) { //based on literature, can become infectious at 96 hours post exposure (will be infectious for sure after four days)
				is_infectious <- true;
				is_latent <- false;
				infectious_time <- 0;
		}
		}
	}
	reflex stop_infectious when: is_infectious{
		old_infectious_time <- infectious_time;
		infectious_time <-old_infectious_time+1;
		if infectious_time=864 { //based on literature, can stop being infectious at 144 hours post becoming infectious
			if flip (0.33){
				is_infectious <-false;
				is_recovered <- true;
				is_infected <- false;
			}
		}
		if infectious_time=1008 { //based on literature, can stop being infectious at 168 hours post becoming infectious
			if flip (0.66){
				is_infectious <-false;
				is_recovered <- true;
				is_infected <- false;
			}
		}
		if infectious_time=1152 { //based on literature, can stop being infectious at 192 hours post becoming infectious
			if flip (1){
				is_infectious <-false;
				is_recovered <- true;
				is_infected <- false;
			}
		}
	}
	reflex stay_at_home_assign when: cycle=3024 and sah_complete=false{
		ask int(0.4*nb_people) among people{
			stay_at_home<-true;
			sah_counter<-sah_counter+1;
			write sah_counter;
	}
		sah_complete<-true;
	}
	
	reflex time_to_work when: current_date.hour = start_work and objective= "resting" and stay_at_home=false{
		objective <- "working";
		the_target <- work_location;
	}
	reflex time_to_visit when: current_date.hour = start_visit and objective="resting" and stay_at_home=false{
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
	reflex record_every_100 when: ((cycle mod 100)=0) and cycle!=0 and rh_complete=false{
		ask 1 among people{
		add nb_people_ever_infected to: hundred_list;
		//write hundred_list;
		
		}
		rh_complete<-true;
	}
	
	reflex reset_record_every_100 when: ((cycle mod 100)!=0) and rh_complete=true{
		rh_complete<-false;
	}
	
	aspect base {
		draw circle(1) color: is_infectious ? #red: color border: #black;
	}
}

experiment Alachua type:gui{
	parameter "Shapefile for large buildings:" var: shape_file_work_buildings category: "GIS" ;
	parameter "Shapefile for small buildings:" var: shape_file_home_buildings category: "GIS" ;
	parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Nb people infected at init" var: nb_infected_init min:1 max: 247336;
	parameter "Work Infectiousness Parameter" var: w_infect_param init:0.000066125 min:0.00001 max:1.0;
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
experiment '100 times' type:batch repeat: 100 until: cycle>12101 parallel: 8 {
	parameter "Shapefile for large buildings:" var: shape_file_work_buildings category: "GIS" ;
	parameter "Shapefile for small buildings:" var: shape_file_home_buildings category: "GIS" ;
	parameter "Shapefile for the bounds:" var: shape_file_bounds category: "GIS" ;
	parameter "Shapefile for the roads:" var: shape_file_roads category: "GIS" ;
	parameter "Number of people agents" var: nb_people category: "People" ;
	parameter "Nb people infected at init" var: nb_infected_init min:1 max: 247336;
	parameter "Work Infectiousness Parameter" var: w_infect_param init:0.000066125 min:0.00001 max:1.0;
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
		
		}
	reflex end_of_runs{
		list comp_hundred_list;
		ask simulations{
			add (self.hundred_list) to: comp_hundred_list;
			}
		save[comp_hundred_list] to: "results_Alachua_40_3024_100.csv" type:csv rewrite: false;
	}
}
	