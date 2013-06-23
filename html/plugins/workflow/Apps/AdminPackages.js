dojo.provide("plugins.workflow.Apps.AdminPackages");

/* SUMMARY: DISPLAY ONE OR MORE PACKAGES SHARED BY THE ADMIN USER

	-	EACH PACKAGE IS DISPLAYED IN ITS OWN apps OBJECT
	
	-	ADMIN USER CREATES AND ADMINISTERS PACKAGE/APPS IN Apps PANE
*/

// INTERNAL MODULES
dojo.require("plugins.workflow.Apps.Packages");

dojo.declare("plugins.workflow.Apps.AdminPackages", [ plugins.workflow.Apps.Packages, plugins.core.Common ], {

/////}

// CORE WORKFLOW OBJECTS
core : null,

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachNode : null,

// ARRAY OF plugins.workflow.Apps.Apps OBJECT
packageApps : [],

getAppsArray : function () {
	return Agua.getAdminApps();
}
	
}); // plugins.workflow.Apps.AdminPackages

