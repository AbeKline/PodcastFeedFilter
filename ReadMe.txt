This is decidedly a work in progress.
Subcaster takes in a single podcast feed like ones from patreon, then filters it into individual shows which are output as .rss files which can be hosted on any webserver (such as Nginx) allowing you to rehost your feeds as individual shows




TODO:
	Compatibilitiy expansion:
		convert to bash
		modularize features and make into functions 
	
	Feature expansion:
		Filter by more than just title
		Dynamically grab the image and meta-data for the Etc feed
		Make the whole thing work in xml, nixing the cumbersome string manipulations
		Toggle allowing the filter to edit the publish date to refelct episode order
			this will be basically an infinite hole of customization
		Persist the file? Could catch bugs in the feed