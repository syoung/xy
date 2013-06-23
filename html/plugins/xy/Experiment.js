define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-class",
	"plugins/core/Common/Util",
	"dojo/ready",
	"dojo/domReady!",

	"dijit/_Widget",
	"dijit/_TemplatedMixin",
	"dijit/form/Select"
	],

function (declare, arrayUtil, JSON, on, lang, domClass, CommonUtil, ready) {

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

/////}}}}}

constructor : function(args) {
	console.log("Experiment.constructor");

	dojo.mixin(this, args);
	
	this.loadCSS();
},
postCreate : function() {
	this.startup();
},
startup : function () {
	console.log("Experiment.startup");

	this.setVariables(this.variables);
},

setVariables : function (variables) {
	delete this.inputList;
	this.inputList = [];
	
	// ADD VARIABLES
	for ( var i = 0; i < variables; i++ ) {
		var textbox = new Textbox({
			label			: 	variables[1]
		});
		console.log("Xy.setVariableInputs    textbox: " + textbox);
		console.dir({textbox:textbox});

		// PUSH TO this.inputList
		this.inputList.push(textbox);
		
		// ADD TO PAGE
		this.variableInputs.appendChild(textbox.containerNode);
	}
	
},


}); 	//	end declare

});	//	end define
