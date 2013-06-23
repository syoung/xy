dojo.provide("plugins.view.Controller");

// OBJECT:  plugins.view.Controller
// PURPOSE: GENERATE AND MANAGE View PANES

// INHERITS
dojo.require("plugins.core.Common");

// HAS
dojo.require("plugins.view.View");

dojo.declare( "plugins.view.Controller",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
	/////}}
	
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("", "../plugins/view/templates/controller.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILE FOR BUTTON STYLING
cssFiles : [
	dojo.moduleUrl("plugins") + "view/css/controller.css"
],

// ARRAY OF TAB PANES
tabPanes : [],

////}}}

// CONSTRUCTOR	
constructor : function(args) {
	console.log("Controller.constructor     plugins.view.Controller.constructor");
	//console.log("Controller.args: " + dojo.toJson(args));

	// LOAD CSS FOR BUTTON
	this.loadCSS();
	
},


postCreate : function() {
	console.log("Controller.postCreate    plugins.view.Controller.postCreate()");

	this.startup();
},


startup : function () {
	console.log("Controller.startup    plugins.view.Controller.startup()");

	this.inherited(arguments);

	// ADD MENU BUTTON TO TOOLBAR
	Agua.toolbar.addChild(this.menuButton);

	// SET BUTTON PARENT WIDGET
	this.menuButton.parentWidget = this;
	
	// SET BUTTON LISTENER
	var listener = dojo.connect(this.menuButton, "onClick", this, "createTab");
},


createTab : function (args) {
	console.log("Controller.createTab    args: ");
	console.dir({args:args});

	// CLEAR ANNOYING ALL-SELECTED
	window.getSelection().removeAllRanges();
	
	if ( args == null ) args = new Object;
	args.attachWidget = Agua.tabs;

	// CREATE WIDGET	
	var widget = new plugins.view.View(args);
	this.tabPanes.push(widget);

	// ADD TO _supportingWidgets FOR INCLUSION IN DESTROY	
	this._supportingWidgets.push(widget);
}




}); // end of Controller


dojo.addOnLoad(
	function()
	{
		//console.log("Controller.addOnLoad    plugins.view.Controller.addOnLoad");
		
		// DEBUG
		//Agua.controller["view"].createTab();
	}
);

