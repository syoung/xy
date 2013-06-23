// REGISTER MODULE PATHS
dojo.registerModulePath("doh","../../dojo-1.6.1rc2/util/doh");	
dojo.registerModulePath("plugins","../../plugins");	
dojo.registerModulePath("t","../../t");	

// DOJO TEST MODULES
dojo.require("dijit.dijit");
//dojo.require("dojox.robot.recorder");
//dojo.require("dijit.robot");
dojo.require("doh.runner");

// Agua TEST MODULES
dojo.require("t.doh.util");

// DEBUG LOADER
dojo.require("dojoc.util.loader");

// REGISTER module path FOR PLUGINS
dojo.registerModulePath("plugins","../../plugins");	

// DEBUG LOADER
dojo.require("dojoc.util.loader");

// TESTED MODULES
dojo.require("plugins.core.Agua");
dojo.require("plugins.workflow.Grid");

var Agua;
var Data;
var projectPanel;

dojo.addOnLoad(function(){

	Agua = new plugins.core.Agua( {
		cgiUrl : "../../../../../../cgi-bin/agua/",
		htmlUrl : "../../../../agua/",
		//,
		////dataUrl: "../../../../t/json/getData-workflow-runstatus.json"
		dataUrl: "../../../../t/json/getData.json"
	});
	
	Agua.cookie('username', 'aguatest');
	Agua.cookie('sessionid', '9999999999.9999.999');
	Agua.loadPlugins([
	"plugins.data.Controller",
	"plugins.workflow.Controller"
]);

	var projectPanel = new plugins.workflow.Grid({
		attachNode : Agua.tabs
	});

	
	
});
