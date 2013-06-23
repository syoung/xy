dojo.provide("plugins.sharing.Access");

// ALLOW THE ADMIN USER TO ADD, REMOVE AND MODIFY USERS

// NEW USERS MUST HAVE username AND email

//dojo.require("dijit.dijit"); // optimize: load dijit layer
dojo.require("dijit.form.Button");
dojo.require("dijit.form.TextBox");
dojo.require("dijit.form.Textarea");
dojo.require("dojo.parser");
dojo.require("dojo.dnd.Source");
dojo.require("plugins.core.Common");

// FORM VALIDATION
dojo.require("plugins.form.ValidationTextarea");

// HAS A
dojo.require("plugins.sharing.AccessRow");

dojo.declare("plugins.sharing.Access",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ],
{
		
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "sharing/templates/access.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// OR USE @import IN HTML TEMPLATE
cssFiles : [ dojo.moduleUrl("plugins") + "sharing/css/access.css" ],

// PARENT WIDGET
parentWidget : null,

// ROW WIDGETS
accessRows : new Array,

// PERMISSIONS
rights: [
	'groupwrite', 'groupcopy', 'groupview', 'worldwrite', 'worldcopy', 'worldview'
],

/////}}}
	
constructor : function (args) {
	////console.log("Access.constructor     plugins.sharing.Access.constructor()");

	////console.log("Access.constructor     this.accessRows: " + this.accessRows);

	// GET INFO FROM ARGS
	this.parentWidget = args.parentWidget;
	this.tabContainer = args.tabContainer;

	this.loadCSS();
	////console.log("Access.constructor     AFTER this.loadCSS()");
},

postMixInProperties: function() {
},

postCreate: function() {
	this.startup();
},

startup : function () {
	////console.log("Access.startup    plugins.sharing.Clusters.startup()");
	////console.log("Access.startup     this.accessRows: " + this.accessRows);

	// COMPLETE CONSTRUCTION OF OBJECT
	this.inherited(arguments);	 

	// ADD ADMIN TAB TO TAB CONTAINER		
	this.tabContainer.addChild(this.accessTab);
	this.tabContainer.selectChild(this.accessTab);

	//////////console.log("Access.++++ plugins.sharing.Access.postCreate()");
	this.buildTable();

	// SUBSCRIBE TO UPDATES
	Agua.updater.subscribe(this, "updateGroups");
},

updateGroups : function (args) {
// RELOAD RELEVANT DISPLAYS
	//console.log("sharing.Access.updateGroups    sharing.Access.updateGroups(args)");
	//console.log("sharing.Access.updateGroups    args:");
	//console.dir(args);

	this.buildTable();
},

buildTable : function () {
	//console.log("Access.buildTable     plugins.sharing.Access.buildTable()");
	//console.log("Access.buildTable     this.table: " + this.table);
	
	// GET ACCESS TABLE DATA
	var accessArray = Agua.getAccess();
	//console.log("Access.buildTable    accessArray: " + dojo.toJson(accessArray));	
	
	// CLEAN TABLE
	if ( this.table.childNodes )
	{
		while ( this.table.childNodes.length > 2 )
		{
			this.table.removeChild(this.table.childNodes[2]);
		}
	}

	// BUILD ROWS
	//console.log("Access.buildTable::groupTable     Doing group rows, accessArray.length: " + accessArray.length);
	this.tableRows = [];
	for ( var rowCounter = 0; rowCounter < accessArray.length; rowCounter++)
	{
	//console.log("Access.buildTable::groupTable     accessArray[" + rowCounter + "]: " + dojo.toJson(accessArray[rowCounter], true));
		accessArray[rowCounter].parentWidget = this;
		var accessRow = new plugins.sharing.AccessRow(accessArray[rowCounter]);
	//console.log("Access.buildTable::groupTable     Doing group rows, accessRow: " + accessRow);
	//console.log("Access.buildTable::groupTable     Doing group rows, accessRow.row: " + accessRow.row);
		this.table.appendChild(accessRow.row);
		this.tableRows.push(accessRow);
	}
	//console.log("Access.buildTable     Completed buildTable");
	
},	// buildTable

togglePermission : function (event) {
	var parentNode = event.target.parentNode;
	////console.log("Access.buildTable     parentNode: " + parentNode);
	
	var nodeClass = event.target.getAttribute('class');
	if ( nodeClass.match('allowed') )
	{
		dojo.removeClass(event.target,'allowed');
		dojo.addClass(event.target,'denied');
	}
	else
	{
		dojo.removeClass(event.target,'denied');
		dojo.addClass(event.target,'allowed');
	}
},

saveAccess : function () {
	////console.log("Access.saveAccess     plugins.sharing.Access.saveAccess()");
	////console.log("Access.saveAccess     this.tableRows.length: " + this.tableRows.length);

	// COLLECT DATA HERE
	var dataArray = new Array;
	for ( var i = 0; i < this.tableRows.length; i++ )
	{
		var data = new Object;
		data.owner 		= Agua.cookie('username');
		data.groupname	= this.tableRows[i].args.groupname;
		for ( var j = 1; j < this.rights.length; j++ )
		{
			data[this.rights[j]] = 0;
			if ( dojo.hasClass(this.tableRows[i][this.rights[j]], 'allowed') )
				data[this.rights[j]] = 1;
		}
		dataArray.push(data);
	}

	// CREATE JSON QUERY
	var url = Agua.cgiUrl + "agua.cgi";
	var query = new Object;
	query.username = Agua.cookie('username');
	query.sessionid = Agua.cookie('sessionid');
	query.mode = "saveAccess";
	query.module 		= 	"Sharing";
	query.data = dataArray;
	////console.log("Access.saveAccess     query: " + dojo.toJson(query));
	
	// SEND TO SERVER
	dojo.xhrPut(
		{
			url: url,
			contentType: "text",
			putData: dojo.toJson(query),
			handle: function(response, ioArgs) {
				Agua.toast(response);
			}
		}
	);
}


}); // plugins.sharing.Access

