define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/on",
	"dojo/when",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dijit/registry",
	"dojo/json",
	"dojo/store/Observable",
	//"plugins/xy/DataStore",
	"plugins/exchange/Exchange",
	"plugins/core/Common",
	"plugins/form/ValidationTextBox",
	//"plugins/graph/Graph",
	"dojo/ready",
	"dojo/domReady!",
	
	"plugins/dojox/layout/ExpandoPane",
	"dijit/TitlePane",
	"dijit/_Widget",
	"dijit/_Templated",

	"dojox/layout/ExpandoPane",
	"dojo/data/ItemFileReadStore",
	"dojo/store/Memory",
	"dijit/layout/AccordionContainer",
	"dijit/layout/TabContainer",
	"plugins/dijit/layout/TabContainer",
	"dijit/layout/ContentPane",
	"dojox/layout/ContentPane",
	"dojox/layout/FloatingPane",
	"dijit/layout/BorderContainer",
	"dijit/form/Button",
	"dijit/form/ValidationTextBox",
	"dijit/form/Select"
],

function (declare, arrayUtil, on, when, lang, domAttr, domClass, registry, JSON, Observable, Exchange, Common, Textbox, ready) {

////}}}}}

return declare("plugins.xy.Xy",[dijit._Widget, dijit._Templated, Common], {

// Path to the template of this widget. 
// templatePath : String
templatePath : require.toUrl("plugins/xy/templates/xy.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// core: Hash
// { dataStore : DataStore object, etc. ...}
core : null,

// dataStore : Store of class Observable(Memory)
//		Watches changes in the data and reacts accordingly
dataStore : null,

// cssFiles : Array
// CSS FILES
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/xy/css/xy.css"),
	require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	require.toUrl("plugins/xy/images/elusive/css/elusive-webfont.css")
],

// callback : Function reference
// Call this after module has loaded
callback : null,

// url: String
// URL FOR REMOTE DATABASE
url: null,

// doneTypingInterval : Integer
// Run 'setTimeout' when this timing interval ends
doneTypingInterval : 1000,

// refreshing : Boolean
//		Set to true if still loading data, false when load is completed
refreshing : false,

//////}}
constructor : function(args) {		
	console.log("Xy.constructor    args:");
	console.dir({args:args});

	// SET Xy GLOBAL
	Xy = this;
	
	if ( ! args )	return;
	
	// DEFAULT ATTACH WIDGET (OVERRIDE IN args FOR TESTING)
	this.attachPoint = Agua.tabs;	

    // MIXIN ARGS
    lang.mixin(this, args);

	// SET CORE
	this.core = new Object;
	this.core.xy = this;

	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "agua.cgi";

	// LOAD CSS
	this.loadCSS();
},
postCreate : function() {
	console.log("Xy.postCreate    plugins.xy.Xy.postCreate()");
	this.startup();
},
startup : function () {
	console.log("Xy.startup    plugins.xy.Xy.startup()");
	if ( ! this.attachPoint ) {
		console.log("Xy.startup    this.attachPoint is null. Returning");
		return;
	}
	
	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	// ADD PANE TO CONTAINER
	this.attachPane();
	
	// SET DEFAULT VARIABLES
	this.setVariables(1);
	//// SET VARIABLE SELECT
	//this.setVariableSelect();

	//// SET EXCHANGE 
	//this.core.exchange = this.setExchange();	
},
// ATTACH PANE
attachPane : function () {

	console.log("Xy.attachPane    caller: " + this.attachPane.caller.nom);
	console.log("Xy.attachPane    this.mainTab: " + this.mainTab);
	console.dir({this_mainTab:this.mainTab});
	console.log("Xy.attachPane    this.attachPoint: " + this.attachPoint);
	console.dir({this_attachPoint:this.attachPoint});
		
	if ( this.attachPoint.addChild ) {
		this.attachPoint.addChild(this.mainTab);
		this.attachPoint.selectChild(this.mainTab);
	}
	if ( this.attachPoint.appendChild ) {
		this.attachPoint.appendChild(this.mainTab.domNode);
	}
},
// TOGGLE CREATE
toggleCreate : function () {
	console.log("Xy.toggleCreate");

	domClass.toggle(this.createExperiment, "visible");
},

// CREATE VARIABLES SELECT
setVariableSelect : function () {
	console.log("Xy.setVariableSelect    ");
	
	this.setSelectOptions("variableSelect", [1,2], null);	
},
setSelectOptions : function (selectName, array, selected) {
	var options = [];
	var first = true;
	for ( var index in array ) {
		var item = array[index];
		//console.log("Base.setSelectOptions    item: " + item);
		if ( ! selected ) {
			if ( first )
				options.push({ label: item, value: item, 'selected': true });
			else
				options.push({ label: item, value: item });
			first = false;
		}
		else {
			if ( item == selected )
				options.push({ label: item, value: item, 'selected': true });
			else
				options.push({ label: item, value: item });
		}
	}
	
	//console.log("DOING this[" + selectName + "].setOptions(options)");

	this.setOptions(selectName, options);
},
setOptions : function (selectName, options) {

	//var optionString = "";
	//for ( var i in options ) {
	//	optionString += "<option class='options' value='" + options[i].value + "'";
	//	if ( options[i].selected )
	//		optionString += " selected='selected'" ;
	//	optionString += ">";
	//	optionString += options[i].label + "</option>\n";
	//}

	console.log("Xy.setOptions   this[" + selectName + "]:");
	console.dir({this_selectName:this[selectName]});
	console.log("Xy.setOptions   options:");
	console.dir({options:options});

	this[selectName].set('options', options);
},
// VARIABLE INPUTS
setVariableInputs : function () {
	var value =  this.variableSelect.value;
	console.log("Xy.setVariableInputs    value: " + value);

	console.log("Xy.setVariableInputs    this.variableInputs: " + this.variableInputs);
	console.dir({this_variableInputs:this.variableInputs});
	
	this.clearVariableInputs();
	
	this.setVariables(value);
},
getVariables : function () {
	console.log("Xy.getVariables");
	var variables = [];
	for ( var i = 0; i < this.inputList.length; i++ ) {
		console.log("Xy.getVariables    variable " + i + ": " + this.inputList[0]);
		var value = this.inputList[i].input.value;
		console.log("Xy.getVariables    value " + i + ": " + value);

		variables.push(value);
	}	
	
	return variables;
},
setVariables : function (value) {
	delete this.inputList;
	this.inputList = [];
	
	// ADD VARIABLES
	for ( var i = 0; i < value; i++ ) {
		var textbox = new Textbox({
			label			: 	'Variable ' + (i + 1).toString()
		});
		console.log("Xy.setVariableInputs    textbox: " + textbox);
		console.dir({textbox:textbox});

		// PUSH TO this.inputList
		this.inputList.push(textbox);
		
		// ADD TO PAGE
		this.variableInputs.appendChild(textbox.containerNode);
	}
	
},
clearVariableInputs : function () {
	this.variableInputs.innerHTML = "";

	while ( this.variableInputs.childNodes != null && this.variableInputs.childNodes.length != 0 ) {
		this.variableInputs.removeChild(this.variableInputs.childNodes[0]);
	}	

},
// SAVE
save : function () {
	console.log("Xy.save    this.inputList: ");
	console.dir({this_inputList:this.inputList});
	
	var variables = this.getVariables();
	console.log("Xy.save    variables: ");
	console.dir({variables:variables});

	// CREATE JSON QUERY
	var url 			=	Agua.cgiUrl + "xy.cgi";
	var query 			= 	new Object;
	query.username 		= 	Agua.cookie('username');
	query.sessionid 	= 	Agua.cookie('sessionid');
	query.mode 			= 	"createExperiment";
	query.module 		= 	"Xy::Base";
	query.variables 	= 	variables;
	query.experiment	=	this.experimentName.value;
	console.log("Packages.deleteItem    query: " + dojo.toJson(query));

	this.doPut({url: url, query: query, doToast: false});
},
// EXCHANGE
setExchange : function () {
// Listen and respond to socket.IO messages
	console.log("Xy.setExchange");

	// SET TOKEN
	this.core.token = this.getToken();

	// INSTANTIATE EXCHANGE...
	var promise = when(this.core.exchange = new Exchange({}));
	console.log(".......................... Xy.setExchange    this.core.exchange:");
	console.dir({this_exchange:this.core.exchange});

	//// ... THEN CONNECT
	//promise.then(this.core.exchange.connect());

	//// SET onMessage LISTENER
	var thisObject = this;
	this.core.exchange.onMessage = function (json) {
		console.log("Xy.setExchange    this.core.exchange.onMessage FIRED    json:");
		console.dir({json:json});
		var data = JSON.parse(json);
		
		thisObject.onMessage(data);
	};
	
	try {
		this.core.exchange.connect();
	} catch(e) {
		console.log("Xy.setExchange    *** CAN'T CONNECT TO SOCKET ***");;
	}
	
	//// CONNECT
	//var thisObject = this;
	//setTimeout(function(){
	//	thisObject.core.exchange.connect();
	//},
	//1000);	

	return this.core.exchange;
},
getToken : function () {
	this.token = this.randomString(16, 'aA#');
	console.log("Xy.getToken    this.token: " + this.token);
},
getTaskId : function () {
	return this.randomString(16, 'aA');
},
randomString : function (length, chars) {
    var mask = '';
    if (chars.indexOf('a') > -1) mask += 'abcdefghijklmnopqrstuvwxyz';
    if (chars.indexOf('A') > -1) mask += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (chars.indexOf('#') > -1) mask += '0123456789';
    if (chars.indexOf('!') > -1) mask += '~`!@#$%^&*()_+-={}[]:";\'<>?,./|\\';
    var result = '';
    for (var i = length; i > 0; --i) result += mask[Math.round(Math.random() * (mask.length - 1))];
    return result;
},
onMessage : function (message) {

// summary:
//		Process the data in the client based on the type of message queue, whether the
//		client is the original sender, filtering by topic pattern, etc.
//		The following inputs are required:
//			queue		:	Type of message queue: fanout, routing, publish, topic and request
//				fanout	:	Run callback on all clients except the sender
//				routing	:	Run callback only in the sender client
//				publish	:	Run callback in all clients that have subscribed to the topic
//				topic	:	Run callback in all clients that pattern match the topic
//				request	:	Ignore (destined for server)
//			token		:	Token of the originating client
//			callback	:	Function to be called
//			data		:	A data hash to be passed to the callback function
//
//		NB: The above queues will be gradually implemented and may be changed or added to
//

	console.log("Xy.onMessage    message: " + message);
	console.dir({message:message});

	// GET INPUTS	
	var queue =	message.queue;
	var sender = false;
	if ( message.token == this.token )	sender = true;	
	var callback	=	message.callback;	
	console.log("Xy.onMessage    queue: " + queue);
	console.log("Xy.onMessage    sender: " + sender);
	console.log("Xy.onMessage    callback: " + callback);
	
	if ( sender && queue == "fanout" ) return;
	if ( sender && queue == "routing" ) {
		console.log("Xy.onMessage    DOING this[" + callback + "](message)");
		this[callback](message);
	}
},
// BOTTOM PANE
updateBottomPane : function (type, name) {
	console.log("Xy.updateBottomPane    type: " + type);
	console.log("Xy.updateBottomPane    name: " + name);
	console.log("Xy.updateBottomPane    bottomPane: ");
	console.dir({this_bottomPane:this.bottomPane});
	console.log("Xy.updateBottomPane.iconNode    bottomPane.iconNode: ");
	console.dir({this_bottomPane_iconNode:this.bottomPane.iconNode});

	// OPEN IF CLOSED
	if ( ! this.bottomPane._showing ) {
		this.bottomPane.iconNode.click();
	}
	
	// SET TAB NAME
	var moduleName = type.substring(0,1).toUpperCase() + type.substring(1);
	console.log("Xy.updateBottomPane    moduleName: " + moduleName);
	var tabPane = "detailed" + moduleName + "Tab";
	console.log("Xy.updateBottomPane    tabPane: " + tabPane);
	
	// SELECT TAB
	console.log("Xy.bottomTabContainer    this.bottomTabContainer: " );
	console.dir({this_bottomTabContainer:this.bottomTabContainer});
	console.log("Xy.updateBottomPane    this[tabPane]: " );
	console.dir({this_tabPane:this[tabPane]});
	this.bottomTabContainer.selectChild(this[tabPane]);

	// UPDATE GRID
	this["detailed" + moduleName].updateGrid(name);
},
// RIGHT PANE
populateRightPane : function (dataStore) {
	var target = this.graph;
	//var url = "../graph/graph.html";
	//var url = "../../xy/t/plugins/graph/test.html";

	//var jsonFile = "http://localhost/xy/t/plugins/graph/print-data.json";
	var jsonFile = "t/plugins/graph/test1.csv";

	this.loadPane(target, jsonFile);
},
loadPane : function (target, jsonFile) {
	console.log("Xy.loadPane    target: " + target);
	console.dir({target:target});

	var graph = new Graph();
	//console.log("print    graph: " + graph);
	//console.dir({graph:graph});
	var data = this.fetchSyncJson(jsonFile);
	//console.log("print    data: ");
	//console.dir({data:data});
	
	var text = graph.fetchSyncText(jsonFile);
	var csv = text.split("\n");
	var headers = csv.shift();
	//console.log("print    headers: " + headers);
	
	// LATER: CONFIGURE THIS DYNAMICALLY
	var index1 = 1;
	var index2 = 2;
	var xLabel;
	var yLabel;
	
	// IF THE xLabel AND yLabel ARE NOT PROVIDED AS ARGUMENTS,
	// GET THEM FROM THE CSV HEADER LINE BASED ON THEIR INDEXES
	var xLabel = headers[index1];
	var yLabel = headers[index2];
	
	// SET COLUMNS TO BE EXTRACTED FROM THE FILE BASED ON THEIR INDEXES
	var columns = [index1, index2];
	var values = graph.csvToValues(csv, columns)
	//console.log("print    values: ");
	//console.dir({values:values});
	
	// CONVERT DATE TO UNIX TIME
	for ( var i = 0; i < values.length; i++ ) {
		if ( ! values[i][0] )	continue;
		var array = graph.parseUSDate(values[i][0]);
		
		values[i][0] = ( graph.dateToUnixTime(array[0], array[1], array[2]) ) * 1000;
	}
	
	// JUST REVERSE THE DATA FOR A TEST EXAMPLE
	var values2 = [];
	for ( var i = 0; i < values.length; i++ ) {
		values2[values.length - (i + 1)] = values[i];
	}
	
	var data = [
		{
			key 	: 	"Freq1",
			bar		:	true,
			values	:	values
		}
		,
		{
			key 	: 	"Freq2",
			bar		:	false,
			values	:	values2
		}
	];
	//console.log("print    data: ");
	//console.dir({data:data});
	
	var series = graph.dataToSeries(data);
	//console.log("print    series: ");
	//console.dir({series:series});
	
	graph.print(target, series, "linePlusBarWithFocusChart", "Date", "Freq", "Change in Frequency over Time");
}


}); 	//	end declare

});	//	end define

