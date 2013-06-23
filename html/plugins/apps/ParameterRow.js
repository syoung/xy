dojo.provide("plugins.apps.ParameterRow");

dojo.declare( "plugins.apps.ParameterRow",
	[ dijit._Widget, dijit._Templated ],
{
	////}}
//Path to the template of this widget. 
templatePath: dojo.moduleUrl("plugins", "apps/templates/parameterrow.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// PARENT plugins.apps.Apps WIDGET
parentWidget : null,

constructor : function(args) {
	//console.log("ParameterRow.constructor    plugins.workflow.ParameterRow.constructor(args)");

	this.parentWidget = args.parentWidget;
	this.lockedValue = args.locked;
},

postCreate : function(args) {
	//console.log("ParameterRow.postCreate    plugins.workflow.ParameterRow.postCreate(args)");
	this.formInputs = this.parentWidget.formInputs;
	this.startup();
},

startup : function () {
	//console.log("ParameterRow.startup    plugins.workflow.ParameterRow.startup()");
	this.inherited(arguments);
	
	// CONNECT TOGGLE EVENT
	var thisObject = this;
	dojo.connect( this.name, "onclick", function(event) {
		thisObject.toggle();
	});

	// SET LISTENER TO LEVEL ROW HEIGHTS
	this.setRowHeightListeners();

	// LEVEL ROW HEIGHT
	//this.levelRowHeight(this);
	//this.levelRowHeight(this);
	//this.toggleNode(this.args);
	//this.toggleNode(this.inputParams);

	//console.log("ParameterRow.startup    this.lockedValue: " + this.lockedValue);
	// SET LOCKED CLASS
	if ( this.lockedValue == 1 )	{
		dojo.removeClass(this.locked,'unlocked');
		dojo.addClass(this.locked,'locked');
	}
	else	{
		dojo.removeClass(this.locked,'locked');
		dojo.addClass(this.locked,'unlocked');
	}

	// ADD 'ONCLICK' EDIT VALUE LISTENERS
	var thisObject = this;
	var onclickArray = [ "argument", "category", "value", "description", "format", "args", "inputParams", "paramFunction" ];
	for ( var i in onclickArray )
	{
		dojo.connect(this[onclickArray[i]], "onclick", function(event)
			{
				console.log("ParameterRow.startup    onclick listener fired: " + onclickArray[i]);
				thisObject.parentWidget.editRow(thisObject, event.target);
				event.stopPropagation(); //Stop Event Bubbling
			}
		);
	}

	// ADD 'ONCHANGE' COMBO BOX LISTENERS
	var thisObject = this;
	var onchangeArray = [ "valuetype", "ordinal", "discretion", "paramtype" ];
	for ( var i in onchangeArray )
	{
		dojo.connect(this[onchangeArray[i]], "onchange", function(event)
			{
				console.log("ParameterRow.startup    onchange listener fired: " + onchangeArray[i]);
				var inputs = thisObject.parentWidget.getFormInputs(thisObject);
				thisObject.parentWidget.saveInputs(inputs, {originator: thisObject.parentWidget, reload: false});
				event.stopPropagation(); //Stop Event Bubbling
			}
		);
	}	
},

setRowHeightListeners : function () {

	var thisObject = this;
	dojo.connect(this.args, 'onchange', dojo.hitch(function (event) {
		////console.log("ParameterRow.setRowHeightListeners    args    this: " + this);
		////console.log("ParameterRow.setRowHeightListeners    args    thisObject: " + thisObject);
		////console.log("ParameterRow.setRowHeightListeners    args.onchange");
		//thisObject.levelRowHeight(thisObject);
		setTimeout(function(thisObj){ thisObj.levelRowHeight(thisObj)}, 100, thisObject);
		event.stopPropagation();
	}));
	dojo.connect(this.inputParams, 'onchange', dojo.hitch(function (event) {
		////console.log("ParameterRow.setRowHeightListeners    inputParams    this: " + this);
		////console.log("ParameterRow.setRowHeightListeners    inputParams    thisObject: " + thisObject);
		////console.log("ParameterRow.setRowHeightListeners    inputParams.onchange");
		setTimeout(function(thisObj){ thisObj.levelRowHeight(thisObj)}, 100, thisObject);
		event.stopPropagation();
	}));
	
},

levelRowHeight : function (paramRow) {
	//console.log("XXXX ParameterRow.levelRowHeight    plugins.workflow.ParameterRow.levelRowHeight()");
	//console.log("ParameterRow.levelRowHeight    BEFORE paramRow.args.clientHeight: " + paramRow.args.clientHeight);
	//console.log("ParameterRow.levelRowHeight    BEFORE this.inputParams.clientHeight: " + paramRow.inputParams.clientHeight);
	//console.log("ParameterRow.levelRowHeight    BEFORE paramRow.args.offsetHeight: " + paramRow.args.offsetHeight);
	//console.log("ParameterRow.levelRowHeight    BEFORE this.inputParams.offsetHeight: " + paramRow.inputParams.offsetHeight);

	// VIEW CURRENT STYLES
	//console.log("paramRow.args.style : " + dojo.attr(paramRow.args, 'style'));
	//console.log("paramRow.inputParams.style : " + dojo.attr(paramRow.inputParams, 'style'));

	// SET STYLES TO max-height TO SQUASH DOWN EMPTY SPACE
	dojo.attr(paramRow.inputParams, 'style', 'display: inline-block; max-height: ' + paramRow.inputParams.clientHeight + 'px !important');
	dojo.attr(paramRow.args, 'style', 'display: inline-block; max-height: ' + paramRow.args.clientHeight + 'px !important');
	dojo.attr(paramRow.inputParams, 'style', { display: "inline-block", "min-height": "20px !important" });
	dojo.attr(paramRow.args, 'style', {	display: "inline-block", "min-height": "20px !important" });
	//console.log("ParameterRow.levelRowHeight    AFTER max-height this.args.clientHeight       : " + paramRow.args.clientHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER max-height this.inputParams.clientHeight: " + paramRow.inputParams.clientHeight);

	//console.log("AFTER max-height    paramRow.args        : " + dojo.attr(paramRow.args, 'style'));
	//console.log("AFTER max-height    paramRow.inputParams : " + dojo.attr(paramRow.inputParams, 'style'));
	
	if ( paramRow.inputParams.clientHeight < paramRow.args.clientHeight )
	{
		//console.log("paramRow.inputParams.height < paramRow.args.height");
		//console.log("Doing set inputParams height = args height")
	
		dojo.attr(paramRow.inputParams, 'style', 'display: inline-block; height: 0px !important');
		dojo.attr(paramRow.inputParams, 'style', 'display: inline-block; min-height: ' + paramRow.args.offsetHeight + 'px !important');
	
	}
	else if ( paramRow.inputParams.clientHeight >= paramRow.args.clientHeight )
	{
			//console.log("paramRow.inputParams.clientHeight >= paramRow.args.clientHeight");
		
			dojo.attr(paramRow.args, 'style', 'display: inline-block; height: 0px !important');
			dojo.attr(paramRow.args, 'style', 'display: inline-block; min-height: ' + paramRow.inputParams.offsetHeight + 'px !important');
	}

	//console.log("ParameterRow.levelRowHeight    AFTER paramRow.args.clientHeight   : " + paramRow.args.clientHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER this.inputParams.clientHeight: " + paramRow.inputParams.clientHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER paramRow.args.offsetHeight   : " + paramRow.args.offsetHeight);
	//console.log("ParameterRow.levelRowHeight    AFTER this.inputParams.offsetHeight: " + paramRow.inputParams.offsetHeight);

	//console.log("paramRow.args.style : " + dojo.attr(paramRow.args, 'style'));
	//console.log("paramRow.inputParams.style : " + dojo.attr(paramRow.inputParams, 'style'));
},

toggle : function () {
// TOGGLE HIDDEN NODES
	//////console.log("ParameterRow.toggle    plugins.workflow.ParameterRow.toggle()");
	//////console.log("ParameterRow.toggle    this.description: " + this.description);

	var array = [ "argument", "valuetype", "valuetypeToggle", "category", "value", "ordinal", "ordinalToggle", "description", "format", "args", "inputParams", "paramFunction" ];
	for ( var i in array )
	{
		this.toggleNode(this[array[i]]);
	}


	var style = dojo.attr(this.args, 'style');
	var display = style.match(/display:\s*([^;]+)/)[1];
	if ( display == "inline-block" )
		this.levelRowHeight(this);
},

toggleNode : function(node) {
	if ( node.style.display == 'inline-block' ) node.style.display='none';
	else node.style.display = 'inline-block';
	
},

toggleLock : function (event) {
	console.log("ParameterRow.toggleLock    plugins.apps.Parameter.toggleLock(name)");
	
	if ( dojo.hasClass(this.locked, 'locked')	){
		dojo.removeClass(this.locked, 'locked');
		dojo.addClass(this.locked, 'unlocked');
		Agua.toastMessage({
			message: "ParameterRow has been unlocked. Users can change this parameter",
			type: warning
		});
	}	
	else {
		dojo.removeClass(this.locked, 'unlocked');
		dojo.addClass(this.locked, 'locked');

		Agua.toastMessage({
			message: "ParameterRow has been locked. Users cannot change this parameter",
			type: "warning" 
		});
	}	

	var inputs = this.parentWidget.getFormInputs(this);
	this.parentWidget.saveInputs(inputs, null);
	event.stopPropagation(); //Stop Event Bubbling
},

formInputs : {
// FORM INPUTS AND TYPES (word|phrase)
	locked : "",
	name: "word",
	argument: "word",
	type: "word",
	category: "word",
	value: "word",
	discretion: "word",
	description: "phrase",
	format: "word",
	args: "word",
	inputParams: "phrase",
	paramFunction: "phrase"
}




});
