/**
* Name: NewModel
* Based on the internal empty template. 
* Author: nchri
* Tags: 
*/


model NewModel

/* Insert your model definition here */
global {
	init {
		list b<- range(0,5);
		file try1 <- csv_file("../includes/try1.csv");
		///loop el over: try1 {
			///list a;
			///write el;
			///a<-el;
			///write a;
		write b;
		
			
		///}
	}
}

experiment myExperiment {}