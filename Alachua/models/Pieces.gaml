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
	
///reflex reset_infection_try when: every(11 #mn){
		///infection_try<-false;
		///}	