dojo.provide("plugins.home.Home");

if ( 1 ) {
// BASIC LAYOUT
dojo.require("dijit.layout.BorderContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dojox.io.windowName");
dojo.require("dojox.layout.ResizeHandle");
dojo.require("dijit.form.Button");
dojo.require("dojox.widget.Standby");
dojo.require("dojox.widget.Dialog");
dojo.require("dojox.fx.easing");
dojo.require("dojox.timing");

// UPGRADE LOG
dojo.require("plugins.dojox.layout.FloatingPane");

// PACKAGE COMBOBOX
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("dijit.form.ComboBox");

// DIALOG WITH COMBOBOX
dojo.require("plugins.dijit.SelectiveDialog");

// NO UPGRADES DIALOG
dojo.require("dijit.Dialog");

// INHERITS
dojo.require("plugins.core.Common");
	
}

dojo.declare( "plugins.home.Home", 
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "home/templates/home.html"),

cssFiles : [
    dojo.moduleUrl("plugins", "home/css/home.css"),
    dojo.moduleUrl("dojox", "layout/resources/ResizeHandle.css"),
	dojo.moduleUrl("dojox", "layout/resources/FloatingPane.css"),
	dojo.moduleUrl("dojox", "widget/Dialog/Dialog.css")
],

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PANE WIDGETS
paneWidgets : null,

// AGUA WIKI
url : "http://ukch-confluence.illumina.com/display/xy/Home",
//url : "https://ukch-confluence.illumina.com/display/servicesSD/Home",
//url : "pages/servicesSD/SaffronDB.html",
//url : "http://www.aguadev.org/confluence/display/home/Home",

// UPGRADE PROGRESS DIALOG
progressPane : null,

// timerInterval
// Number of milliseconds between calls to onTick
// timerInterval : Integer
timerInterval : 30000,

// controller
// Widget containing multiple instances of this class as tabs
controller : null,

////}}}}

constructor : function(args) {	
	// LOAD CSS
	this.loadCSS();		

	this.controller = args.controller;
},
postCreate : function() {
	console.log("Home.postCreate    plugins.home.Home.postCreate()");

	this.startup();
},
startup : function () {
	console.log("Home.startup    plugins.home.Home.startup()");
	console.log("Home.startup    this.mainTab");
	console.dir({this_mainTab:this.mainTab});

	this.inherited(arguments);

	// ADD ADMIN TAB TO TAB CONTAINER		
	Agua.tabs.addChild(this.mainTab);

	Agua.tabs.selectChild(this.mainTab);

	// LOAD PANE 
	this.loadPane();

	// CONNECT WINDOW AND PROGRESS PANE RESIZE
	dojo.connect(this.mainTab.controlButton, "onClickCloseButton", dojo.hitch(this, "onClose"));
},
onClose : function (args) {
    console.log("Home.onClose    caller: " + this.onClose.caller.nom);
    console.log("Home.onClose    args: ");
    console.dir({args:args});

    console.log("Home.onClose    DOING this.controller.removeTab(this)");
    this.controller.removeTab(this);    
},
destroyRecursive : function () {
	console.log("Home.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
//	if ( Agua && Agua.tabs )
//		Agua.tabs.removeChild(this.mainTab);

    // REMOVE UPDATE SUBSCRIPTIONS
    this.removeUpdateSubscriptions();

    var widgets = dijit.findWidgets(this.mainTab);
	console.log("Home.destroyRecursive    widgets: ");
	console.dir({widgets:widgets});
    dojo.forEach(widgets, function(w) {
        w.destroyRecursive(true);
    });

	this.destroy();
	this.inherited(arguments);

    // REMOVE THIS WIDGET FROM REGISTRY
//	console.log("Home.destroyRecursive    this.isd: " + this.id);
//    dojo.registry.remove(this.id);
},
loadPane : function () {
	var url = this.url;
	console.log("Home.loadPane    url: " + url);

	var auth = true;
	var authTarget = this.bottomPane;
	if ( this.bottomPane.id == null )
		this.bottomPane.id = this.id + "_windowName";
	this.windowDeferred = dojox.io.windowName.send(
		"GET",
		{
			url: url,
			handleAs:"text",
			authElement: authTarget,
			onAuthLoad: auth && function () {
				authTarget.style.display='block';
				console.log("Changed authTarget style.display to 'block'");
			}
		}
	);
	
	this.windowDeferred.addBoth(function(result){
		console.dir({result: result});
		auth && (authTarget.style.display='none');
		alert(result)
	});
},



}); // end of plugins.home.Home
