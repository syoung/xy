dojo.provide("plugins.workflow.Apps.AppSource");

dojo.require("plugins.form.DndSource");

dojo.declare( "plugins.workflow.Apps.AppSource",
	[ dijit._Widget, dijit._Templated, plugins.form.DndSource  ],
{

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "workflow/Apps/templates/appsource.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.workflow.Apps WIDGET
parentWidget : null,

// CONTEXT MENU
contextMenu : null,

// ROW CLASS
rowClass : "plugins.workflow.Apps.AppRow",

// AVATAR ITEMS
avatarItems : ["name", "description"],

// FORM INPUTS (DATA ITEMS TO BE ADDED TO ROWS)
formInputs : {
	name:			1,
	owner:			1,
	type:			1,
	version:		1,
	executor:		1,
	localonly:		1,
	location:		1,
	description:	1,
	notes:			1,
	url :			1
},

/////}}}

constructor : function(args)
{
	////console.log("AppSource.constructor    plugins.workflow.AppSource.constructor()");
	this.parentWidget = args.parentWidget;
	this.itemArray = args.itemArray;
	this.contextMenu = args.contextMenu;
},

postCreate : function()
{
	////console.log("AppSource.postCreate    plugins.workflow.AppSource.postCreate()");
	this.startup();
},

startup : function ()
{
	////console.log("AppSource.startup    plugins.workflow.AppSource.startup()");
	////console.log("AppSource.startup    this.parentWidget: " + this.parentWidget);

	this.inherited(arguments);

	this.setDragSource();
},

getItemArray : function ()
{
	//console.log("AppSource.getItemArray    plugins.workflow.AppSource.getItemArray()");
	//console.log("AppSource.getItemArray.length    this.itemArray.length: " + this.itemArray.length);
	return this.itemArray;
}

	
});
