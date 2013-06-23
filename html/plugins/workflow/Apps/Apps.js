dojo.provide("plugins.workflow.Apps.Apps");

// ALLOW THE USER TO SELECT FROM 'AGUA' USER AND 'ADMIN' USER APPLICATIONS AND DRAG THEM INTO WORKFLOWS

// EXTERNAL MODULES
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");

// INTERNAL MODULES
dojo.require("plugins.core.Common");
dojo.require("plugins.workflow.Apps.AppSource");
dojo.require("plugins.workflow.Apps.AppRow");
dojo.require("plugins.workflow.Apps.AppMenu");

dojo.declare("plugins.workflow.Apps.Apps",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/Apps/templates/apps.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [
	dojo.moduleUrl("plugins", "workflow/Apps/css/apps.css")
],

// CORE WORKFLOW OBJECTS
core : null,

// APPS CONTAINED BY THIS WIDGET
apps : [],

// PARENT WIDGET
parentWidget : null,

// ATTACH NODE
attachNode : null,

// TAB CONTAINER
tabContainer : null,

// CONTEXT MENU
contextMenu : null,

////}	

constructor : function (args) {
	////////console.log("Apps.constructor     plugins.workflow.Apps.constructor");			
	// GET INFO FROM ARGS
	this.core = args.core;
    this.apps = args.apps;
	this.parentWidget = args.parentWidget;
	this.attachNode = args.attachNode;
    
    // LOAD CSS
	this.loadCSS();		
},
postCreate : function () {
	this.startup();
},
startup : function () {
	////////console.log("Apps.startup    plugins.workflow.Apps.startup()");

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD TO TAB CONTAINER		
	this.attachNode.addChild(this.mainTab);
	this.attachNode.selectChild(this.mainTab);

	// CREATE SOURCE MENU
	////////console.log("Apps.startup    DOING this.setContextMenu()");
	this.setContextMenu();
	
	// SET APP TITLE
	this.setPackageName();
	
	// SET APP TITLE
	this.setOwnerName();

	// SET DRAG APP - LIST OF APPS
	////////console.log("Apps.startup    DOING this.loadAppSources()");
	this.loadAppSources();
	
	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateApps");
},
setContextMenu : function () {
// GENERATE CONTEXT MENU
	//////console.log("Apps.setContextMenu     plugins.workflow.Apps.setContextMenu()");	
	this.contextMenu = new plugins.workflow.Apps.AppMenu( {
			parentWidget: this
		}
	);	
},
setPackageName : function () {
	var apps = this.apps;
	console.log("Apps.setPackageName    apps: ");
	console.dir({apps:apps});
	
	// RETURN IF APPS IS EMPTY
	if ( ! apps || ! apps[0] )	return;	
	
	// GET PACKAGE NAME
	var packageName = apps[0]["package"];
	if ( ! packageName )	packageName = "";
	packageName = this.firstLetterUpperCase(packageName);
	console.log("Apps.setPackageName    packageName: " + packageName);

	// SET TITLE
	this.mainTab.set("title", packageName);	
},
setOwnerName : function () {
	var apps = this.apps;
	console.log("Apps.setPackageName    apps: ");
	console.dir({apps:apps});
	
	// RETURN IF APPS IS EMPTY
	if ( ! apps || ! apps[0] )	return;	
	
	// GET PACKAGE NAME
	var ownerName = apps[0]["owner"];
	if ( ! ownerName )	ownerName = "";
	console.log("Apps.setPackageName    ownerName: " + ownerName);

	// SET SUBTITLE
	var subTitle = "Owner: " + ownerName;
	this.ownerName.innerHTML = subTitle;	
},
updateApps : function (args) {
	////////console.log("Apps.refresh     plugins.workflow.Apps.refresh()");
	//console.log("Apps.updateApps    args:");
	//console.dir(args);
	this.loadAppSources();
},
closePanes : function () {
	//console.log("Apps.closePanes     plugins.workflow.Apps.closePanes()");

	if ( this.appSources == null || this.appSources.length == 0 )	return;
	for ( var i = 0; i < this.appSources.length; i++ )
	{
        var titlePane = this.appSources[i].titlePane;
        //console.log("Apps.closePanes     titlePane: " + titlePane);
        if ( titlePane.open == true )
            titlePane.toggle();
	}
},
clearAppSources : function () {
// DELETE EXISTING APP SOURCES
	//console.log("Apps.clearAppSources     plugins.workflow.Apps.clearAppSources()");
	if ( this.appSources == null || this.appSources.length == 0 )	return;
	
	for ( var i = 0; i < this.appSources.length; i++ ) {
		//console.log("Apps.clearAppSources     Destroying this.appSources[" + i + "]: " + this.appSources[i]);
		this.appSources[i].clearDragSource();
		this.appSourcesContainer.removeChild(this.appSources[i].domNode);
		this.appSources[i].destroy();
	}
},
getAppsByType : function (type, apps) {
	//console.log("Apps.getAppsByType    plugins.workflow.Apps.getAppsByType(type)");
	//console.log("Apps.getAppsByType    type: " + type);
	var keyArray = ["type"];
	var valueArray = [type];
	var cloneapps = dojo.clone(apps);

	return this.filterByKeyValues(cloneapps, keyArray, valueArray);
},
loadAppSources : function () {
	//console.log("Apps.loadAppSources     plugins.workflow.Apps.loadAppSources()");

	// DELETE EXISTING CONTENT
	this.clearAppSources();

	var apps = this.apps;
	//console.log("Apps.loadAppSources     apps: " + dojo.toJson(apps));
	var types = Agua.getAppTypes(apps);
	//console.log("Apps.loadAppSources     types: " + dojo.toJson(types));
	
	this.appSources = new Array;
	for ( var i = 0; i < types.length; i++ )
	{
		var type = types[i];
		//console.log("Apps.loadAppSources     Doing type: " + dojo.toJson(type));		

		// GET APPLICATIONS
		var itemArray = this.getAppsByType(type, apps);
		if ( itemArray == null || itemArray.length == 0 )	continue;
		//console.log("Apps.loadAppSources     itemArray: " + dojo.toJson(itemArray));

		// CREATE TITLE PANE
		var appSource = new plugins.workflow.Apps.AppSource(
		{
			title		: 	type,
			itemArray 	:	itemArray,
			contextMenu	:	this.contextMenu
			
		});
		this.appSources.push(appSource);
		this.appSourcesContainer.appendChild(appSource.domNode);
	}
}

}); // plugins.workflow.Apps
