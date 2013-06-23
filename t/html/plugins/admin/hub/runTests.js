// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo-1.6.1rc2/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t");	

// DOJO TEST MODULES
//dojo.require("dijit.dijit");
////dojo.require("dojox.robot.recorder");
////dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// TESTED MODULES
dojo.require("plugins.core.Agua")

// GLOBAL Agua VARIABLE
var Agua;

dojo.addOnLoad(function(){

// SET UP
Agua = new plugins.core.Agua( {
	cgiUrl 		:	dojo.moduleUrl("plugins", "../../../cgi-bin/agua/")
	, database	: 	"aguatest"
	, dataUrl	: 	"test.json"
});
Agua.cookie('username', 'aguatest');
Agua.cookie('sessionid', '9999999999.9999.999');
Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.admin.Controller",
	"plugins.workflow.Controller"
]);

Agua.controllers["admin"].createTab();
Agua.controllers["workflow"].createTab();

// RUN TESTS
doh.register("t.plugins.admin.hub.test", [
{

	name	: 	"updateSyncs-disabled",
	timeout	:	30000,
	
	runTest	: function(){
	
		// CLEAR CONSOLE
		console.clear();
		console.log("HERE");
	
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();
			
		// OPEN DIRECTORIES AUTOMATICALLY
		setTimeout(function() {
			try {
				console.log("runTests    updateSyncs");
		
				var hub = Agua.data.hub;
				console.dir({hub:hub});
				
				// DELETE HUB LOGIN
				delete Agua.data.hub.login;

				// DO UPDATES
				Agua.updater.update("updateSyncWorkflows");
				Agua.updater.update("updateSyncApps");
	
				// GET APPS
				var apps = Agua.controllers["admin"].tabPanes[0].paneWidgets["plugins.admin.Apps"][0];
				console.log("apps:")
				console.dir({apps:apps});
	
				// GET WORKFLOWS
				var userWorkflows = Agua.controllers["workflow"].tabPanes[0].core.userWorkflows;
				console.log("userWorkflows:")
				console.dir({userWorkflows:userWorkflows});
	
				// GET APPS DISABLED
				var disabled = dojo.hasClass(apps.syncAppsButton, "disabled");
				console.log("apps.syncAppsButton is disabled: " + disabled)
				doh.assertTrue(disabled);
				console.log("AFTER");
	
				// GET WORKFLOWS DISABLED
				disabled = dojo.hasClass(userWorkflows.syncWorkflowsButton, "disabled");
				console.log("userWorkflows.syncWorkflowsButton is disabled: " + disabled)
				doh.assertTrue(disabled);
				
				
				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 1000);
	
		return deferred;
	}

},
{
	name	: 	"updateSyncs-enabled",
	timeout	:	30000,
	
	runTest	: function(){
	
		// CLEAR CONSOLE
		console.clear();
		console.log("HERE");
	
		// SET DEFERRED OBJECT
		var deferred = new doh.Deferred();
			
		// OPEN DIRECTORIES AUTOMATICALLY
		setTimeout(function() {
			try {
				console.log("runTests    updateSyncs");
		
				var hub = Agua.data.hub;
				console.dir({hub:hub});
	
				// SET HUB LOGIN
				Agua.data.hub.login = "aguatest";

				// DO UPDATES
				Agua.updater.update("updateSyncWorkflows");
				Agua.updater.update("updateSyncApps");
	
				// GET APPS
				var apps = Agua.controllers["admin"].tabPanes[0].paneWidgets["plugins.admin.Apps"][0];
				console.log("apps:")
				console.dir({apps:apps});
	
				// GET WORKFLOWS
				var userWorkflows = Agua.controllers["workflow"].tabPanes[0].core.userWorkflows;
				console.log("userWorkflows:")
				console.dir({userWorkflows:userWorkflows});
	
				// GET APPS DISABLED
				var disabled = dojo.hasClass(apps.syncAppsButton, "disabled");
				console.log("apps.syncAppsButton is disabled: " + disabled)
				doh.assertFalse(disabled);
				console.log("AFTER");
	
				// GET WORKFLOWS DISABLED
				disabled = dojo.hasClass(userWorkflows.syncWorkflowsButton, "disabled");
				console.log("userWorkflows.syncWorkflowsButton is disabled: " + disabled)
				doh.assertFalse(disabled);
				
				
				deferred.callback(true);
	
			} catch(e) {
			  deferred.errback(e);
			}
		}, 1000);
	
		return deferred;
	}
}

]);	// doh.register


//Execute D.O.H. in this remote file.
doh.run();




	

});

