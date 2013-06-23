dojo.provide("plugins.workflow.Apps.AguaPackages");

/* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE AGUA USER

	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
	
	-	PACKAGES ARE LOADED WHEN INSTALLING/UPDATING bioapps PACKAGE
*/

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.workflow.Apps.Apps");
dojo.require("plugins.workflow.Apps.Packages");

dojo.declare("plugins.workflow.Apps.AguaPackages", [ plugins.core.Common, plugins.workflow.Apps.Packages ], {

/////}}}

// CORE WORKFLOW OBJECTS
core : null,

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachNode : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECT
packageApps : [],

setPackages : function () {
	console.log("AguaPackages.setPackages    className: " + this.getClassName(this));
	var apps = this.getAppsArray();
	console.log("AguaPackages.setPackages    apps: ");
	console.dir({apps:apps});

	var packages = this.hashArrayKeyToArray(apps, "package");
    packages = this.uniqueValues(packages);
	console.log("AguaPackages.setPackages    packages: ");
	console.dir({packages:packages});
	console.log("AguaPackages.setPackages    packages.length: " + packages.length);
	
	if ( ! packages || packages.length < 1 )	return;
	
	for ( var i = 0; i < packages.length; i++ ) {
		var packageName = packages[i];
		var applications = dojo.clone(apps);
		applications = this.filterByKeyValues(applications, ["package"], [packageName]);
		console.log("AguaPackages.setPackages    packageName " + packageName + " applications: ");
		console.dir({applications:applications});
		
		console.log("AguaPackages.setPackages    applications.length: " + applications.length);
		if ( applications.length < 1 )    continue;

		// CREATE APPS OBJECT		
		var appsObject = this.createAppsObject(applications);
		console.log("AguaPackages.setPackages    appsObject: " + appsObject);
        
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
	return Agua.getAguaApps();
}

	
}); // plugins.workflow.Apps.Packages

