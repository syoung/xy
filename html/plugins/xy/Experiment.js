define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-class",
	"dojo/dom-construct",
	"plugins/core/Common/Util",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/form/Select"
],

function (declare, arrayUtil, JSON, on, lang, domClass, domConstruct, CommonUtil, ready) {

return declare("plugins.form.Select",
	[ dijit._Widget, dijit._TemplatedMixin, CommonUtil ], {
		
//Path to the template of this widget. 
templatePath: require.toUrl("plugins/xy/templates/experiment.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

_earlyTemplatedStartup: true,

noStart : false,
 
// OR USE @import IN HTML TEMPLATE
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("dijit/themes/dijit.css"),
	require.toUrl("dijit/themes/soria/soria.css"),
	require.toUrl("dijit/themes/tundra/tundra.css"),
	require.toUrl("plugins/xy/css/experiment.css")
],

// variables : Array
//		Array of variable names
variables : [],

// entries : Array
//		Array of variable names
entries : [],

/////}}}}}

constructor : function(args) {
	console.log("Experiment.constructor   args:");
	console.dir({args:args});
	
	dojo.mixin(this, args);
	
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	console.log("Experiment.startup");

	this.setDateTime();
	
	this.setVariables(this.entries);
},
setDateTime : function () {
	console.log("Experiment.setDateTime");
	var datetime = this.mysqlToDate(this.entries[0].datetime);

	console.log("Experiment.setDateTime    datetime: " + datetime);

	this.datetime.innerHTML = datetime;
},

mysqlToDate : function (datetime) {
// format: 2007-06-05 15:26:02
	var regex=/^([0-9]{2,4})-([0-1][0-9])-([0-3][0-9]) (?:([0-2][0-9]):([0-5][0-9]):([0-5][0-9]))?$/;
	var parts = datetime.replace(regex,"$1 $2 $3 $4 $5 $6").split(' ');
	return new Date(parts[0],parts[1]-1,parts[2],parts[3],parts[4],parts[5]);
},
setVariables : function (entries) {
	console.log("Experiment.setVariables    entries: " + entries);
	console.dir({entries:entries});
	
	// ADD VARIABLES
	for ( var i = 0; i < entries.length; i++ ) {
		console.log("Experiment.setVariables    entries[i]: " + entries[i]);
		console.dir({entries_i:entries[i]});
		console.log("Experiment.setVariables    type: " + entries[i].type);
		
		var div = domConstruct.create("div", null, this.variableList);
		div.innerHTML = entries[i].type;
		domClass.add(div, "variable");
	}
},


}); 	//	end declare

});	//	end define
