dojo.provide("plugins.workflow.Apps.Packages");

/* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE ADMIN USER

	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
	
	-	ADMIN USER CREATES AND ADMINISTERS PACKAGE/APPS IN Apps PANE
*/


// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.workflow.Apps.Apps");

dojo.declare("plugins.workflow.Apps.Packages", [ plugins.core.Common ], {

/////}}}

// CORE WORKFLOW OBJECTS
core : null,

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachNode : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECTS
packageApps : [],

constructor : function (args) {
	console.group("Packages    " + this.id + "    constructor");
	console.log("Packages.constructor    args: " + args);

	// GET INFO FROM ARGS
	this.core = args.core;
	this.parentWidget = args.parentWidget;
	this.attachNode = args.attachNode;
	
	this.startup();
	console.groupEnd("Packages    " + this.id + "    constructor");
},
startup : function() {
	console.log("Packages.startup    workflow.Apps.Packages.startup()");
	
	this.setPackages();
},
setPackages : function () {
	console.log("Packages.setPackages    className: " + this.getClassName(this));
	var apps = this.getAppsArray();
	console.log("Packages.setPackages    apps: ");
	console.dir({apps:apps});

	var packages = this.hashArrayKeyToArray(apps, "package");
    packages = this.uniqueValues(packages);
	console.log("Packages.setPackages    packages: ");
	console.dir({packages:packages});
	console.log("Packages.setPackages    packages.length: " + packages.length);
	
	if ( ! packages || packages.length < 1 )	return;
	
	for ( var i = 0; i < packages.length; i++ ) {
		var packageName = packages[i];
		var applications = dojo.clone(apps);
		applications = this.filterByKeyValues(applications, ["package"], [packageName]);
		console.log("Packages.setPackages    packageName " + packageName + " applications: ");
		console.dir({applications:applications});
		
		console.log("Packages.setPackages    applications.length: " + applications.length);
		if ( applications.length < 1 )    continue;

		// CREATE APPS OBJECT		
		var appsObject = this.createAppsObject(applications);
		console.log("Packages.setPackages    appsObject: " + appsObject);
        
        // PUSH TO this.packageApps
        this.packageApps.push(appsObject);		
	}
},
createAppsObject : function (applications) {
	var appsObject = new plugins.workflow.Apps.Apps({
		apps: applications,
		core: this.core,
		parentWidget: this.parentWidget,
		attachNode: this.attachNode
	});
},
getAppsArray : function () {
	// OVERRIDE THIS
}

	
}); // plugins.workflow.Apps.Packages

