dojo.provide("plugins.view.View");

/* CLASS SUMMARY: CREATE AND MODIFY VIEWS
	
	TAB HIERARCHY IS AS FOLLOWS:
	
		tabs	

			mainTab

				leftPane (SELECT VIEW AND FEATURE TRACKS)

					comboBoxes

				rightPane (VIEW GENOMIC BROWSER)

						Browser

							Features (DRAG AND DROP FEATURE TRACKS LIST)

							GenomeView (GOOGLE MAPS-STYLE GENOME NAVIGATION)


	USE CASE SCENARIO 1: USER ADDS A FEATURE TO A VIEW

		OBJECTIVE:
		
			1. MINIMAL ACTION TO ACHIEVE THE DESIRE RESULT
			
			2. IMMEDIATE AND ANIMATED RESPONSES TO INDICATE STATUS/PROGRESS


		IMPLEMENTATION:
		
		1. USER SELECTS FEATURE IN BOTTOM OF LEFT PANE AND CLICKS 'Add'
		
		2. IF FEATURE ALREADY EXISTS IN VIEW, DO NOTHING.

		3. OTHERWISE, addViewFeature CALL TO REMOTE WILL RETURN STATUS OR AN ERROR:
		
			IF STATUS IS 'Adding feature: featureName':
				
				1. START DELAYED POLL FOR STATUS
			
				2. POLL WILL STOP WHEN STATUS IS 'ready'
				
					OR THERE IS AN ERROR RESPONSE
					
				3. IF 'ready' THEN UPDATE CLIENT AND SERVER DATABASES
				
					AND RESET THE VIEW FEATURES COMBO BOX
		
				4. USER CAN CLICK THE 'refresh' BUTTON TO REMOVE ANY ERROR OR 
				
					NON-'ready' STATUS (E.G., PROLONGED 'adding' OR 'removing'
					
					DUE TO ERROR ON REMOTE SERVER):
			
				5. THE 'refresh' BUTTON IS THE VIEW ICON ON LEFT OF VIEW COMBO BOX 
			
			IF STATUS IS DIFFERENT, DO NOTHING.
			
			E.G.: 'Feature already present in view: featureName'
		
		4. IF ERROR, DO NOTHING.
		
			E.G.: 'Undefined inputs: feature, project, view'

*/	
// EXTERNAL MODULES
if ( 1 ) {

// STORE FOR PROJECT AND WORKFLOW COMBOS
dojo.require("dojo.data.ItemFileReadStore");

// DIALOGS
dojo.require("dijit.Dialog");  // NOTES
dojo.require("plugins.dijit.ConfirmDialog");
dojo.require("plugins.dijit.SelectiveDialog");

// TIMER
dojo.require("plugins.dojox.timing.Sequence");

// HAS A
dojo.require("dijit.layout.BorderContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dojox.layout.ExpandoPane");

// WIDGETS IN TEMPLATE
dojo.require("dijit.layout.SplitContainer");
dojo.require("dijit.layout.ContentPane");
dojo.require("dojo.data.ItemFileReadStore");
dojo.require("dijit.form.ComboBox");
dojo.require("dijit.form.Button");
dojo.require("dijit.layout.TabContainer");
dojo.require("dijit.layout.BorderContainer");
dojo.require("dojox.layout.FloatingPane");
dojo.require("dojo.fx.easing");
dojo.require("dojo.parser");

// INTERNAL MODULES

// JBROWSE
//dojo.require("plugins.view.jbrowse.jslib.dojo.jbrowse_dojo");
dojo.require("plugins.view.jbrowse.js.Browser");
dojo.require("plugins.view.jbrowse.js.Util");
dojo.require("plugins.view.jbrowse.js.NCList");
dojo.require("plugins.view.jbrowse.js.Layout");
dojo.require("plugins.view.jbrowse.js.LazyArray");
dojo.require("plugins.view.jbrowse.js.LazyPatricia");
dojo.require("plugins.view.jbrowse.js.Track");
dojo.require("plugins.view.jbrowse.js.SequenceTrack");
dojo.require("plugins.view.jbrowse.js.FeatureTrack");
dojo.require("plugins.view.jbrowse.js.UITracks");
dojo.require("plugins.view.jbrowse.js.ImageTrack");
dojo.require("plugins.view.jbrowse.js.GenomeView");
dojo.require("plugins.view.jbrowse.js.touchJBrowse");

// STANDBY
dojo.require("dojox.widget.Standby");

// GENERAL
dojo.require("plugins.core.Common");
dojo.require("plugins.dijit.SelectiveDialog");
dojo.require("plugins.dojox.Timer");

var refSeqs;
var trackInfo;

dojo.require("dijit._base.place");
}

dojo.declare( "plugins.view.View",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {
// PATH TO WIDGET TEMPLATE
templatePath: dojo.moduleUrl("plugins", "view/templates/view.html"),

// PARENT NODE, I.E., TABS NODE
parentWidget : null,

// PROJECT NAME AND WORKFLOW NAME IF AVAILABLE
project : null,
workflow : null,

// onChangeListeners : Array. LIST OF COMBOBOX ONCHANGE LISTENERS
onChangeListeners : new Object,

// setListeners : Boolean. SET LISTENERS FLAG 
setListeners : false,

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// cssFiles: Array
// CSS FILES
cssFiles : [
	dojo.moduleUrl("plugins", "view/css/view.css"),
	dojo.moduleUrl("plugins", "view/css/genome.css"),
	dojo.moduleUrl("dojox", "layout/resources/ExpandoPane.css"),
	dojo.moduleUrl("dojox", "layout/tests/_expando.css"),
	dojo.moduleUrl("plugins", "dnd/css/dnd.css")
],

// browsers: Array
// HASH ARRAY OF OPENED BROWSERS
browsers : new Array,

// url: String
// URL FOR REMOTE DATABASE
url: null,

// baseUrl : String
// BASE URL FOR VIEW DATA
baseUrl: "plugins/view/jbrowse/",

// browserUrl : String
// ROOT URL FOR Browser.js OBJECT
browserRoot : "plugins/view/jbrowse/",

// polling : Bool
// Polling for completion of new view
polling : false,

// delay : Int
// Delay between each poll (1000 = 1 second)
delay : 10000,

////}}}
constructor : function(args) {	
	//console.log("View.constructor    plugins.view.View.constructor(args)");

	// SET ARGS
	this.parentWidget = args.parentWidget;
	this.project = args.project;
	this.workflow = args.workflow;
	
	// SET url
	if ( Agua.cgiUrl )	this.url = Agua.cgiUrl + "/agua.cgi";
	
	// LOAD CSS
	if ( args["cssFiles"] != null ) this.cssFiles = args.cssFiles;
	//console.log("View.constructor    this.cssFiles: " + dojo.toJson(this.cssFiles));
	this.loadCSS(this.cssFiles);		
},
postCreate: function() {
	this.startup();
},
// STARTUP
startup : function () {
	console.log("View.startup    plugins.view.Template.View.startup()");

	console.log("View.constructor    this.browsers:");
	console.dir({this_browsers:this.browsers});
	if ( this.browsers[0] ) {
    	console.log("View.constructor    this.browsers[0].project: " + this.browsers[0].project);
		console.log("View.constructor    this.browsers[0].workflow :" + this.browsers[0].workflow);
    }
	
	
    // ADD THIS WIDGET TO Agua.widgets[type]
    Agua.addWidget("view", this);

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);
	
	// ADD THE PANE TO THE TAB CONTAINER
	this.attachWidget.addChild(this.mainTab);
	this.attachWidget.selectChild(this.mainTab);
	
	// EXPAND LEFT PANE (WAS CLOSED SO THAT RIGHT PANE WOULD RENDER)
	this.leftPane.toggle();

	// SET URL
	this.setUrl();
	
	// SET PROGRESS POLL DELAY OBJECT
	this.setSequence();

	// SET DIALOG WIDGETS
	this.setConfirmDialog();
	this.setSelectiveDialog();

	// SET LOADING STANDBY
	this.setStandby();
	
	// LOAD COMBOS IN SUCCESSION
	this.setViewProjectCombo();
	
	// SET COMBO LISTENERS
	setTimeout(
		function (thisObj) { thisObj.setFeatureProjectCombo(); },
		10,
		this
	);

	// SET VIEW COMBO ONKEYCHANGE LISTENER
	setTimeout(
		function (thisObj) { thisObj.setOnkeyListener(); },
		1000,
		this
	);

	// LOAD BROWSER
	setTimeout(
		function (thisObj) { thisObj.loadBrowser(thisObj.getProject(), thisObj.getView()); },
		2000,
		this
	);	
},
loadEval : function (url) {
	console.log("View.loadEval    url: " + url);
	// SEND TO SERVER
	dojo.xhrGet(
		{
			url: url,
			sync: true,
			handleAs: "text",
			load: function(response) {
				//console.log("View.loadEval    response: " + dojo.toJson(response));
				eval(response);
			},
			error: function(response, ioArgs) {
				console.log("  View.loadEval    Response error. Response: " + response);
				return response;
			}
		}
	);	
},
// GETTERS
getRefseqfile : function (username, projectName, viewName) {
	return this.baseUrl + "/users"
						+ "/" + username
						+ "/" + projectName
						+ "/" + viewName
						+ "/data/refSeqs.js";
},
getTrackinfofile : function (username, projectName, viewName) {
	return this.baseUrl + "/users"
						+ "/" + username
						+ "/" + projectName
						+ "/" + viewName
						+ "/data/trackInfo.js";
},
getProject : function () {
	return this.viewProjectCombo.get('value');
},
getWorkflow : function () {
	return this.workflowCombo.get('value');
},
getView : function () {
	//console.log("view.View.getView    plugins.view.Views.getView()");	
	//console.log("view.View.getView    Returning this.viewCombo.get('value'): " + this.viewCombo.get('value'));
	return this.viewCombo.get('value');
},
getViewFeature : function () {
	return this.featureList.get('value') ?
		this.featureList.get('value') : '' ;
},
getBuild : function () {
	//console.log("View.getBuild    View.getBuild()");
	return this.buildLabel.innerHTML;
},
getSpecies : function () {
	//console.log("View.getSpecies    View.getSpecies()");
	return this.speciesLabel.innerHTML;
},
getFeatureBuild : function () {
	//console.log("View.getFeatureBuild    View.getFeatureBuild()");
	var speciesBuild = this.speciesCombo.get('value');
	//console.log("View.getFeatureBuild    speciesBuild: "+ speciesBuild);

	if ( speciesBuild.match(/^(\S+)\(([^\)]+)\)$/) )
		return  speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[2];
},
getFeatureSpecies : function () {
	//console.log("View.getFeatureSpecies    View.getFeatureSpecies()");
	//console.log("View.getFeatureSpecies    this: " + this);

	var speciesBuild = this.speciesCombo.get('value');
	//console.log("View.getFeatureSpecies    speciesBuild: "+ speciesBuild);

	if ( speciesBuild.match(/^(\S+)\(([^\)]+)\)$/) )
		return speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[1];
},
getFeature : function () {
	return this.featureCombo.get('value');
},
getFeatureProject : function () {
	return this.featureProjectCombo.get('value');
},
getFeatureWorkflow : function () {
	return this.workflowCombo.get('value');
},
setUrl : function () {
	this.url = Agua.cgiUrl + "agua.cgi?";
	return this.url;
},
setSequence : function () {
	this.sequence = new plugins.dojox.timing.Sequence({});
},
setOnkeyListener : function () {
	//console.log("View.setOnkeyListener    plugins.view.View.setOnkeyListener()");

	// SET ONKEYPRESS LISTENER
	var thisObject = this;
	this.viewCombo._onKey = function(event){
		//console.log("View.setOnKeyListener._onKey	  event");
		
		// summary: handles keyboard events
		var key = event.charOrCode;			
		//console.log("View.setOnKeyListener._onKey	    key: " + key);
		if ( key == 13 )
		{
			//thisObject.workflowCombo._hideResultList();
			
			var projectName = thisObject.viewProjectCombo.get('value');
			var viewName = thisObject.viewCombo.get('value');
			//console.log("View.setOnKeyListener._onKey	   projectName: " + projectName);
			//console.log("View.setOnKeyListener._onKey	   thisObject.viewCombo: " + thisObject.viewCombo);
			//console.log("View.setOnKeyListener._onKey	   viewName: " + viewName);
			
			// STOP PROPAGATION
			//event.stopPropagation();
			
			//console.log("View.setOnKeyListener._onKey	   Checking if isView");
			var isView = Agua.isView(projectName, viewName);
			console.log("View.setOnKeyListener._onKey	   isView: " + isView);

			if ( isView == false )	thisObject.confirmAddView(projectName, viewName);
				
			if ( thisObject.viewCombo._popupWidget != null )
			{
				thisObject.viewCombo._showResultList();
			}
		}

		// STOP PROPAGATION
		//event.stopPropagation();
	};
},
setConfirmDialog : function () {
	var yesCallback = function (){};
	var noCallback = function (){};
	var title = "Dialog title";
	var message = "Dialog message";
	
	this.confirmDialog = new plugins.dijit.ConfirmDialog(
		{
			title 				:	title,
			message 			:	message,
			parentWidget 		:	this,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},
loadConfirmDialog : function (title, message, yesCallback, noCallback) {
	////console.log("View.loadConfirmDialog    plugins.files.View.loadConfirmDialog()");
	////console.log("View.loadConfirmDialog    yesCallback.toString(): " + yesCallback.toString());
	////console.log("View.loadConfirmDialog    title: " + title);
	////console.log("View.loadConfirmDialog    message: " + message);
	////console.log("View.loadConfirmDialog    yesCallback: " + yesCallback);
	////console.log("View.loadConfirmDialog    noCallback: " + noCallback);

	this.confirmDialog.load(
		{
			title 				:	title,
			message 			:	message,
			yesCallback 		:	yesCallback,
			noCallback 			:	noCallback
		}			
	);
},
setSelectiveDialog : function () {
	var enterCallback = function (){};
	var cancelCallback = function (){};
	var title = "";
	var message = "";
	
	console.log("Stages.setSelectiveDialog    plugins.files.Stages.setSelectiveDialog()");
	this.selectiveDialog = new plugins.dijit.SelectiveDialog(
		{
			title 				:	title,
			message 			:	message,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
	console.log("Stages.setSelectiveDialog    this.selectiveDialog: " + this.selectiveDialog);
},
loadSelectiveDialog : function (title, message, comboValues, inputMessage, comboMessage, checkboxMessage, enterCallback, cancelCallback) {
	console.log("Stages.loadSelectiveDialog    plugins.files.Stages.loadSelectiveDialog()");
	console.log("Stages.loadSelectiveDialog    enterCallback.toString(): " + enterCallback.toString());
	console.log("Stages.loadSelectiveDialog    title: " + title);
	console.log("Stages.loadSelectiveDialog    message: " + message);
	console.log("Stages.loadSelectiveDialog    enterCallback: " + enterCallback);
	console.log("Stages.loadSelectiveDialog    cancelCallback: " + cancelCallback);


	this.selectiveDialog.load(
		{
			title 				:	title,
			message 			:	message,
			comboValues 		:	comboValues,
			inputMessage 		:	inputMessage,
			comboMessage 		:	comboMessage,
			checkboxMessage		:	checkboxMessage,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback
		}			
	);
},
// COMBO METHODS
setViewProjectCombo : function (projectName, viewName) {
	console.log("View.setViewProjectCombo    projectName: " + projectName);
	console.log("View.setViewProjectCombo    viewName: " + viewName);

	var projects = Agua.getProjects();
	var projectNames = Agua.getProjectNames(projects);
	console.log("View.setViewProjectCombo    BEFORE SORT projectNames: ");
	console.dir({ projectNames: projectNames});
	
	console.log("View.setViewProjectCombo    DOING projectNames.sort(this.sortNaturally)");
	projectNames.sort(this.sortNaturally);

	console.log("View.setViewProjectCombo    AFTER SORT projectNames: ");
	console.dir({ projectName: projectName});

	if ( ! projectNames )
	{
		//console.log("  Common.setViewProjectCombo    projectNames not defined. Returning.");
		return;
	}
	////console.log("  Common.setViewProjectCombo    projects: " + dojo.toJson(projects));

	// DO DATA ARRAY
	var data = {identifier: "name", items: []};
	for ( var i in projectNames )
		data.items[i] = { name: projectNames[i]	};
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );
	this.viewProjectCombo.store = store;	
	
	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( projectName == null || ! projectName)	projectName = projectNames[0];	
	this.viewProjectCombo.setValue(projectName);			
	
	if ( projectName == null )	projectName = this.viewProjectCombo.get('value');

	// RESET THE WORKFLOW COMBO
	//console.log("View.setViewProjectCombo    BEFORE this.setWorkflowCombo(" + projectName + ")");
	this.setViewCombo(projectName, viewName);
},
setViewCombo : function (projectName, viewName) {
	//console.log("View.setViewCombo    plugins.view.View.setViewCombo(projectName, viewName)");
	console.log("View.setViewCombo    projectName: " + projectName);
	console.log("View.setViewCombo    viewName: " + viewName);

	// DO COMBO WIDGET SETUP	
	this.inherited(arguments);
	
	// SET VIEW NAME IF NOT DEFINED
	if ( viewName == null )
	{
		var views = Agua.getViewsByProject(projectName);
		////console.log("View.setViewCombo    views: " + dojo.toJson(views));
		if ( views == null || views.length == 0 )	return;
		if ( views.length > 0 ) viewName = views[0].view;
	}
	//console.log("View.setViewCombo    DOING this.setSpeciesCombo(" + projectName + ", " + viewName + ")");
	
	this.setSpeciesLabel(projectName, viewName);
},
setSpeciesLabel : function (projectName, viewName) {
// SET SPECIES AND BUILD LABELS
	//console.log("View.setSpeciesLabel    plugins.view.View.setSpeciesLabel(projectName, viewName)");
	console.log("View.setSpeciesLabel    projectName: " + projectName);
	console.log("View.setSpeciesLabel    viewName: " + viewName);

	var species = Agua.getSpecies(projectName, viewName);
	this.speciesLabel.innerHTML = species || '';
	var build = Agua.getBuild(projectName, viewName);
	this.buildLabel.innerHTML = build || '';

	// SET SPECIES COMBO VALUE
	var setValue = species + "(" + build + ")";
	this.speciesCombo.set('value', setValue);

	// SET FEATURE LIST
	var viewfeatures = Agua.getViewFeatures(projectName, viewName);
	var featureNames = this.hashArrayKeyToArray(viewfeatures, "feature");
	//for ( var i = 0; i < viewfeatures.length; i++ )
	//	featureNames.push(viewfeatures[i].feature);
	//console.log("View.setSpeciesLabel    featureNames: " + dojo.toJson(featureNames));

	this.setFeatureList(featureNames);
},
setFeatureProjectCombo : function (projectName, workflowName) {
	console.log("Common.setFeatureProjectCombo    projectName: " + projectName);

	var projectNames = Agua.getFeatureProjects();
	console.log("  View.setFeatureProjectCombo    projects: ");
	console.dir({projectNames:projectNames});

	// DO DATA ARRAY
	var data = {identifier: "name", items: []};
	for ( var i in projectNames )
		data.items[i] = { name: projectNames[i]	};

	var store = new dojo.data.ItemFileReadStore( {	data: data	} );
	this.featureProjectCombo.store = store;	
	
	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( projectName == null || ! projectName)
		projectName = projectNames[0];	
	this.featureProjectCombo.setValue(projectName);			
	
	if ( projectName == null )
		projectName = this.featureProjectCombo.get('value');

	// RESET THE WORKFLOW COMBO
	////console.log("Common.setFeatureProjectCombo    BEFORE this.setWorkflowCombo(" + projectName + ")");
	this.setWorkflowCombo(projectName);
},
setWorkflowCombo : function (projectName, workflowName) {
	console.log("View.setWorkflowCombo    projectName: " + projectName);
	console.log("View.setWorkflowCombo    workflowName: " + workflowName);

	if ( projectName == null || ! projectName )	return;
	if ( this.workflowCombo == null )	return;
	
	// CREATE THE DATA FOR A STORE		
	var workflowNames = Agua.getViewProjectWorkflows(projectName);
	console.log("View.setWorkflowCombo    projectName '" + projectName + "' workflowNames: ");
	console.dir({workflowNames:workflowNames});
	
	// RETURN IF workflowNames NOT DEFINED
	if ( ! workflowNames )	return;

	// CREATE store
	var data = {identifier: "name", items: []};
	for ( var i in workflowNames )
		data.items[i] = { name: workflowNames[i]	};
	//////console.log("View.setWorkflowCombo    data: " + dojo.toJson(data));
	var store = new dojo.data.ItemFileReadStore( { data: data } );
	this.workflowCombo.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY IN workflowNames IF NOT DEFINED 
	if ( workflowName == null || ! workflowName )	workflowName = workflowNames[0];
	////console.log("View.setWorkflowCombo    workflowName: " + workflowName);

	this.workflowCombo.startup();
	this.workflowCombo.set('value', workflowName);			

	//// SET CSS
	//this.workflowCombo.popupClass = "view viewCombo dijitReset dijitMenu";
	//this.workflowCombo.wrapperClass = "view dijitPopup";
	//this.workflowCombo.itemHeight = 30;		

	if ( projectName == null ) projectName = this.viewProjectCombo.get('value');
	if ( workflowName == null ) workflowName = this.workflowCombo.get('value');

	// RESET THE VIEW COMBO
	this.setSpeciesCombo(projectName, workflowName);
},
setSpeciesCombo : function (projectName, workflowName, speciesName, buildName) {
	////console.log("View.setSpeciesCombo    plugins.view.View.setSpeciesCombo(projectName, workflowName)");
	////console.log("View.setSpeciesCombo    projectName: " + projectName);
	////console.log("View.setSpeciesCombo    workflowName: " + workflowName);

	// SET DROP TARGET (LOAD MIDDLE PANE, BOTTOM)
	if ( projectName == null ) projectName = this.featureProjectCombo.get('value');
	if ( workflowName == null ) workflowName = this.workflowCombo.get('value');

	var viewfeatures = Agua.getViewWorkflowFeatures(projectName, workflowName);
	if ( viewfeatures == null || viewfeatures.length == 0 ) {
		////console.log("View.setSpeciesCombo    viewfeatures is null or empty. Returning");
		return;
	}
	//////console.log("View.setSpeciesCombo    viewfeatures: " + dojo.toJson(viewfeatures));

	// GET SPECIES+BUILD NAMES
	var speciesBuildNames = new Array;
	for ( var i = 0; i < viewfeatures.length; i++ ) {
		speciesBuildNames.push(viewfeatures[i].species + "(" + viewfeatures[i].build + ")");
	}
	speciesBuildNames = this.uniqueValues(speciesBuildNames);
	////console.log("View.setSpeciesCombo    speciesBuildNames: " + dojo.toJson(speciesBuildNames));

	// SET SPECIES+ BUILD NAME
	var speciesBuildName;
	if ( speciesName == null || ! speciesName
		|| buildName == null || ! buildName ) {
		speciesBuildName = speciesBuildNames[0];
		speciesName = viewfeatures[0].species;
		buildName = viewfeatures[0].build;
	}
	else {
		speciesBuildName = speciesName + "(" + buildName + ")";
	}
	////console.log("View.setSpeciesCombo    speciesBuildName: " + speciesBuildName);

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in speciesBuildNames )
	{
		data.items[i] = { name: speciesBuildNames[i]	};
	}
	var store = new dojo.data.ItemFileReadStore( { data: data } );
	this.speciesCombo.store = store;

	// START UP COMBO (?? NEEDED ??)
	this.speciesCombo.startup();
	this.speciesCombo.set('value', speciesBuildName);			

	this.setFeatureCombo(projectName, workflowName, speciesName, buildName);
},
setFeatureCombo : function (projectName, workflowName, speciesName, buildName) {
	console.log("View.setFeatureCombo    plugins.view.View.setFeatureCombo(projectName, workflowName)");
	console.log("View.setFeatureCombo    projectName: " + projectName);
	console.log("View.setFeatureCombo    workflowName: " + workflowName);

	if ( projectName == null || ! projectName 
		|| workflowName == null || ! workflowName 
		|| speciesName == null || ! speciesName 
		|| buildName == null || ! buildName )
	{
		console.log("View.setFeatureCombo    Project, workflow, species or build not defined. Returning.");
		return;
	}

	// CREATE THE DATA FOR A STORE		
	var featureNames = 	Agua.getViewSpeciesFeatureNames(projectName, workflowName, speciesName, buildName);
	if ( ! featureNames )
	{
		console.log("View.setFeatureCombo    featureNames not defined. Returning.");
		return;
	}
	console.log("View.setFeatureCombo    projectName '" + projectName + "' workflowName '" + workflowName + "' speciesName '" + speciesName + "' buildName '" + buildName + "' featureNames: " + dojo.toJson(featureNames));

	// CREATE store
	var data = {identifier: "name", items: []};
	for ( var i in featureNames )
		data.items[i] = { name: featureNames[i]	};
	console.log("View.setFeatureCombo    data: " + dojo.toJson(data));
	var store = new dojo.data.ItemFileReadStore( { data: data } );
	this.featureCombo.store = store;

	// SET SELECTED VALUE TO FIRST ENTRY IN featureNames
	var featureName = featureNames[0];

	this.featureCombo.startup();
	this.featureCombo.set('value', featureName);			
},
setFeatureList : function (featureNames) {
	//console.log("View.setFeatureList    plugins.view.View.setFeatureList(featureNames)");
	console.log("View.setFeatureList    featureNames: " + dojo.toJson(featureNames));

	var data = {identifier: "name", items: []};
	for ( var i in featureNames )
		data.items[i] = { name: featureNames[i]	};

	// CREATE store
	//console.log("View.setFeatureList    data: " + dojo.toJson(data));
	var store = new dojo.data.ItemFileReadStore( { data: data } );
	this.featureList.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY 
	this.featureList.startup();
	this.featureList.set('value', featureNames[0]);			
},
// POLLING
_delayedPoll : function (viewObject, callback, message) {
	console.log("View._delayedPoll    viewObject:");
	console.dir({viewObject:viewObject});
	//console.log("View._delayedPoll    callback: " + callback);

	var putData 		= 	viewObject;
	putData.mode 		= 	"viewStatus";
	putData.module 		= 	"View";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');
	console.log("View._delayedPoll    putData:");
	console.dir({putData:putData});

	if ( ! message )	message = "";
	var delay = this.delay;
	//console.log("View._delayedPoll    delay: " + delay);
	var commands = [
		{ func: [ this.showMessage, this, message, putData ], pauseAfter: delay }
		, { func: [ this.pollStatus, this, putData, callback ] } 
	];
	
	//console.log("View._delayedPoll    sequence:");
	//console.dir({this_sequence:this.sequence});

	this.sequence.clear();
	this.sequence.go(commands, function() {});	
},
pollStatus : function(putData, callback) {
	console.log("View.pollStatus    putData:");
	console.dir({putData:putData});
	//console.log("View.pollStatus    callback: " + callback);
	console.log("View.pollStatus    this.polling: " + this.polling);

	if ( ! this.polling ) 	return;
	
	var url = this.url;
	var thisObject = this;
	this.pollStatusDeferred = dojo.xhrPut({
		url			: 	url,
		handleAs	: 	"json-comment-optional",
		sync		: 	false,
		putData		:	dojo.toJson(putData),
		handle		: 	function (response) {
			callback(response, putData);
		}
	});
},
stopPoll : function () {
	this.polling = false;
	console.log("View.stopPoll    this.polling: " + this.polling);
	if ( ! this.pollStatusDeferred )	return
	this.pollStatusDeferred.handle = function () {};
},
// VIEW METHODS
refreshView : function () {
/* RESET VIEW STATUS TO 'ready' AND RELOAD PANE */
	console.log("View.refreshView    plugins.view.View.refreshView()");
	
	// HIDE STANDBY
	this.standby.hide();
	
	// DISPLAY LOADING
	this.displayLoading();

	// RELOAD BROWSER
	this.reloadBrowser(this.getProject(), this.getView());

	// PREPARE FEATURE TRACK OBJECT
	var featureObject = new Object;

	// SOURCE FEATURE
	featureObject.feature 		= 	this.getFeature();
	featureObject.sourceproject = 	this.getFeatureProject();
	featureObject.sourceworkflow= 	this.getFeatureWorkflow();
	featureObject.species 		= 	this.getFeatureSpecies();
	featureObject.build 		= 	this.getFeatureBuild();
	// VIEW INFO
	featureObject.project 		= 	this.getProject();
	featureObject.view 			= 	this.getView();
	// USER INFO
	featureObject.username 		= 	Agua.cookie('username');
	featureObject.sessionid 	= 	Agua.cookie('sessionid');
	// MODE
	featureObject.mode 			= 	"refreshView";
	featureObject.module 		= 	"View";

	// DO REMOTE CALL
	var url = Agua.cgiUrl + "agua.cgi";
	var callback = dojo.hitch(this, "_refreshView");
	this.doPut({ url: this.url, query: featureObject, callback: callback });
},
_refreshView : function (response) {
	//console.log("View._refreshView    response: " + dojo.toJson(response));
	//console.log("View._refreshView    this: ");
	;

	// DISPLAY READY
	this.displayReady();

	if ( ! response )	{
		Agua.toastError("Problem reloading 'views'/'viewfeatures'");
	}
	else {
		Agua.setData("views", response.views);
		Agua.setData("viewfeatures", response.viewfeatures);
		this.setViewCombo(this.getProject());
	}
},
updateViewLocation : function (viewObject, location, chrom) {	
	// SKIP IF STILL LOADING
	if ( this.loading == true )	return 1;

	console.log("View.updateViewLocation    location: " + location);

	//console.log("View.updateViewLocation    caller: " + this.updateViewLocation.caller.nom);
	//console.log("View.updateViewLocation    viewObject: " + dojo.toJsonviewObject));
	//console.log("View.updateViewLocation    location: " + location);
	//console.log("View.updateViewLocation    chrom: " + chrom);
	////console.log("View.updateViewLocation    this.loading: ");
	////console.dir({loading:this.loading});
	////console.log("View.updateViewLocation    VIEWS: ");
	////console.dir({views:Agua.data.views})
	
	// SKIP IF LOCATION NOT DEFINED OR NO MATCH
	if ( location == null )	return 1;
	var matches = String(location).match(/^(((\S*)\s*:)?\s*(-?[0-9,.]*[0-9])\s*(\.\.|-|\s+))?\s*(-?[0-9,.]+)$/i);
	if ( matches == null )	return 1;

	// PARSE LOCATION FOR CHROMOSOME, START AND STOP
	//matches[6] = end base (or center base, if it's the only one)
	var chromosome = matches[3];
	if ( chromosome == null)	chromosome = chrom;
	var start = parseInt(matches[4].replace(/[,.]/g, ""));
	var stop = parseInt(matches[6].replace(/[,.]/g, ""));
	//console.log("View.updateViewLocation    chromosome: " + chromosome);
	//console.log("View.updateViewLocation    start: " + start);
	//console.log("View.updateViewLocation    stop: " + stop);

	// SKIP IF BOTH START AND STOP NOT DEFINED
	if ( ! start && ! stop )	return 1;

	//console.log("View.updateViewLocation    BEFORE Agua.getViewObject");
	//console.dir({views:Agua.data.views})
	
	var object = Agua.getViewObject(viewObject.project, viewObject.view);
	//console.log("View.updateViewLocation    object: " + dojo.toJson(object));

	//console.log("View.updateViewLocation    AFTER Agua.getViewObject");
	//console.dir({views:Agua.data.views})

	if ( ! object )
	{
		console.log("View.updateViewLocation    object NOT DEFINED");
		return;
	}
	
	if ( object.chromosome == chromosome
		&& object.start == start
		&& object.stop == stop )	return;

	object.chromosome = chromosome;
	object.start = start;
	object.stop = stop;
	
	//console.log("View.updateViewLocation    BEFORE _removeView(object): " + dojo.toJson(object));
	var success = Agua._removeView(object);
	if ( success != true ) {
		console.log("View.updateViewLocation    Could not do Agua.removeView() for add track to view " + viewObject.view);
		return;
	}
	//console.log("View.updateViewLocation    BEFORE _addView(object): " + dojo.toJson(object));

	success = Agua._addView(object);
	if ( success != true ) {
		////console.log("View.updateViewLocation    Could not do Agua._addView() for update track to view " + viewObject.view);
		return;
	}	
	//////console.log("View.updateViewLocation    Agua.views: " + dojo.toJson(Agua.views, true));

	// ADD STAGE TO stage TABLE IN REMOTE DATABASE
	object.username = Agua.cookie('username');
	object.sessionid = Agua.cookie('sessionid');
	object.mode = "updateViewLocation";
	object.module 		= 	"View";
	//////console.log("View.updateViewLocation    object: " + dojo.toJson(object));

	this.doPut({ url: this.url, query: object, doToast: false });	
},
handleTrackChange : function (viewObject, track, action) {	
	console.log("View.handleTrackChange    view.View.handleTrackChange(viewObject, track, action)");
	if ( this.loading == true )	return 1;

	//console.log("View.handleTrackChange    caller: " + this.handleTrackChange.caller.nom);
	//console.log("View.handleTrackChange    viewObject: " + dojo.toJson(viewObject));
	//console.log("View.handleTrackChange    track: " + track);
	//console.log("View.handleTrackChange    action: " + action);
		
	var object = Agua.getViewObject(viewObject.project, viewObject.view);
	//console.log("View.handleTrackChange    object: " + dojo.toJson(object));

	var tracks = [];
	//console.log("View.handleTrackChange    object.tracklist: " + object.tracklist);
	if ( object.tracklist ){
		tracks = object.tracklist.split(",");
	}
	//console.log("View.handleTrackChange    AFTER GENERATED, tracks: ");
	//console.dir({tracks:tracks});

	var index;
	for ( var i = 0; i < tracks.length; i++ )
	{
		if ( tracks[i] == track )
		{
			index = i;
			continue;
		}
	}
	//console.log("View.handleTrackChange    index: " + index);

	// IF DOING 'ADD', RETURN IF TRACK IS ALREADY IN TRACKLIST
	if ( action == "add" ) {
		if ( index != null )	return 0;
		else	tracks.push(track);
	}
	
	// IF DOING REMOVE, RETURN IF TRACK IS NOT IN TRACKLIST
	if ( action == "remove" ) {
		if ( index == null )	return 1;
		else	tracks.splice(index, 1);
	}
	//console.log("View.handleTrackChange    AFTER tracks: ");
	//console.dir({tracks:tracks});
	
	// REPLACE TRACKLIST IN VIEW WITH NEW VERSION
	object.tracklist = tracks.join(",");
	//console.log("View.updateViewobject.tracklist    AFTER object.tracklist: " + object.tracklist);

	this.updateViewTracklist(object);
},
updateViewTracklist : function (object) {
	console.log("View.updateViewTracklist    object: ");
	console.dir({object:object});
	
	var success = Agua._removeView(object);
	console.log("View.updateViewTracklist    success: " + success);
	console.dir({views:Agua.cloneData("views")});

	if ( ! success ) {
		console.log("View.updateViewTracklist    Could not do Agua._removeView() for view: " + object.view);
		return;
	}
	success = Agua._addView(object);
	console.log("View.updateViewTracklist    Agua._addView(object) success: " + success);
	console.dir({views:Agua.cloneData("views")});
	if ( ! success ) {
		console.log("View.updateViewTracklist    Could not do Agua._addView() for view: " + object.view);
		return;
	}
	
	// COMPLETE QUERY OBJECT
	object.username = Agua.cookie('username');
	object.sessionid = Agua.cookie('sessionid');
	object.mode = "updateViewTracklist";
	object.module 		= 	"View";

	this.doPut({ url: this.url, query: object, doToast : false });	
},
confirmAddView : function (projectName, viewName) {
// DISPLAY A 'Copy Workflow' DIALOG THAT ALLOWS THE USER TO SELECT 
// THE DESTINATION PROJECT AND THE NAME OF THE NEW WORKFLOW
	console.log("View.confirmAddView    plugins.files.View.confirmAddView()");
	console.log("View.confirmAddView    this.selectiveDialog: " + this.selectiveDialog);

	// SET POLLING TO FALSE
	this.polling = false;
	
	var thisObject = this;
	var speciesBuilds = Agua.getSpeciesBuilds();
	console.log("View.confirmAddView    speciesBuilds: " + dojo.toJson(speciesBuilds));

	var cancelCallback = function () {};
	var enterCallback = dojo.hitch(this, function (input, speciesBuild, checked, dialogWidget)
		{
			console.log("View.confirmAddView    Doing enterCallback(input, speciesBuild, checked, dialogWidget)");
			console.log("View.confirmAddView    viewName: " + viewName);
			console.log("View.confirmAddView    projectName: " + projectName);
			console.log("View.confirmAddView    input: " + input);
			console.log("View.confirmAddView    speciesBuild: " + speciesBuild);
			console.log("View.confirmAddView    checked: " + checked);
			console.log("View.confirmAddView    dialogWidget: " + dialogWidget);
			
			dialogWidget.messageNode.innerHTML = "Adding view: " + viewName;
			dialogWidget.close();
			
			console.log("View.confirmAddView    Doing this.addView()");
			thisObject.addView(projectName, viewName, speciesBuild);
		}
	);		

	// SHOW THE DIALOG
	this.selectiveDialog.load(
		{
			title 				:	"Add view: " + viewName,
			message 			:	"Select species/build combination",
			comboValues 		:	speciesBuilds,
			inputMessage 		:	null,
			comboMessage 		:	null,
			checkboxMessage		:	null,
			parentWidget 		:	this,
			enterCallback 		:	enterCallback,
			cancelCallback 		:	cancelCallback,
			enterLabel			:	"Add",
			cancelLabel			:	"Cancel"
		}			
	);
},
// ADD VIEW
addView : function (projectName, viewName, speciesBuild) {
	console.log("View.addView    projectName: " + projectName);
	console.log("View.addView    viewName: " + viewName);
	console.log("View.addView    speciesBuild: " + speciesBuild);
	if ( this.polling ) {
		console.log("View.addView    this.polling is TRUE. Returning");
		return;
	}
	this.polling = true;
	
	// SHOW STANDBY
	this.standby.show();

	// GET SPECIES AND BUILD
	var species = speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[1];
	var build = speciesBuild.match(/^(\S+)\(([^\)]+)\)$/)[2];
	
	// SET SPECIES LABEL TO BLANK
	this.speciesLabel.innerHTML = '';
	this.buildLabel.innerHTML = '';

	var viewObject 		= new Object;
	viewObject.project 	= projectName;
	viewObject.view		= viewName;
	viewObject.species	= species;
	viewObject.build 	= build;
	console.log("View.addView    viewObject: " + viewObject);
	console.dir({viewObject:viewObject});
	
	if ( ! Agua._addView(dojo.clone(viewObject)) ) {
		console.log("View.addView    Could not add view to this.views[" + viewObject.view + "]");
	}

	// ADD VIEW ON REMOTE SERVER
	this._remoteAddView(dojo.clone(viewObject));

	// SET POLL
	console.log("View.addView    Doing this._delayedPoll(dojo.clone(viewObject), this._handleAddView, message)");
	var message = "View._delayedPoll    addView";
	this._delayedPoll(dojo.clone(viewObject), dojo.hitch(this,"_handleAddView"), message);
},
_remoteAddView : function (viewObject) {	
// ADD VIEW ON REMOTE
	console.log("View._remoteAddView    viewObject:");
	console.dir({viewObject:viewObject});

	var putData 		= 	dojo.clone(viewObject);
	putData.mode 		= 	"addView";
	putData.module 		= 	"View";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');

	var url 			= this.url;
	var callback 		= function (response) {
		console.log("View._remoteAddView    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("View._remoteAddView    Error adding view");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleAddView : function (response, viewObject) {
	console.log("View._handleAddView    response: ");
	console.dir({response:response});
	console.log("View._handleAddView    viewObject: ");
	console.dir({viewObject:viewObject});
	
	if ( response.status == 'ready' ) {
		this.polling = false;
		this.standby._setTextAttr("");
		this.standby.hide();
		this.displayReady();
		
		// SET VIEW COMBO
		console.log("View._handleAddView    Doing this.setViewCombo()");
		this.setViewCombo(viewObject.project, viewObject.view);

		// RELOAD BROWSER
		console.log("View._handleAddView    Doing this.reloadBrowser()");
		this.reloadBrowser(viewObject.project, viewObject.view)

		Agua.toastInfo("Added view: " + viewObject.view);
	}
	else if ( response.error ) {
		this.polling = false;
		this.standby.hide();
		this.displayReady();
		console.log("View.addView    Error on remote. Response: ");
		console.dir({response:response});
	}
	else {
		console.log("View._delayedPoll    Doing this._delayedPoll(dojo.clone(viewObject), this._handleAddView, message)");
		var message = "View._delayedPoll    addView";
		this._delayedPoll(dojo.clone(viewObject), dojo.hitch(this,"_handleAddView"), message);
	}
},
// REMOVE VIEW
confirmRemoveView : function () {
	var noCallback = function () {};
	var yesCallback = dojo.hitch(this, function () {
		this.removeView();
	});
	
	// SET TITLE AND MESSAGE
	var projectName = this.getProject();
	var viewName 	= this.getView();
	var title = "Delete view '" + projectName + "." + viewName + "' ?";
	var message = "All its data will be destroyed";

	// SHOW THE DIALOG
	this.loadConfirmDialog(title, message, yesCallback, noCallback);
},
removeView : function () {
	console.log("View.removeView    plugins.view.View.removeView()");

	var projectName = 	this.getProject();
	var viewName 	= 	this.getView();
	var species 	=	this.getSpecies();
	var build		=	this.getBuild();
	console.log("View.removeView    projectName: " + projectName);
	console.log("View.removeView    viewName: " + viewName);
	console.log("View.removeView    species: " + species);
	console.log("View.removeView    build: " + build);

	// SET SPECIES LABEL TO BLANK
	this.speciesLabel.innerHTML = '';
	this.buildLabel.innerHTML = '';

	var viewObject 		= new Object;
	viewObject.project 	= projectName;
	viewObject.view		= viewName;
	viewObject.species	= species;
	viewObject.build 	= build;
	console.log("View.removeView    viewObject: " + viewObject);
	console.dir({viewObject:viewObject});

	this._removeView(dojo.clone(viewObject));

	// REMOVE BROWSER
	console.log("View._removeView    Doing this.removeBrowser()");
	var browserObject = this.getBrowser(viewObject.project, viewObject.view);
	console.log("View._removeView    browserObject: ");
	console.dir({browserObject:browserObject});
	if ( browserObject )
		this.removeBrowser(browserObject.browser, viewObject.project, viewObject.view);
	
	// SET VIEW PROJECT COMBO
	var previousView = Agua.getPreviousView(viewObject);
	console.log("View.removeView    previousView: ");
	console.dir({previousView:previousView});
	if ( previousView ) {
		console.log("View.removeView    XXX DOING this.setViewProjectCombo(previousView.project, previousView.view)");
		this.setViewProjectCombo(previousView.project, previousView.view);
	}

	Agua.toastInfo("Removed view: " + viewObject.view);

	this._remoteRemoveView(dojo.clone(viewObject));	
},
_removeView : function (viewObject) {
// REMOVE VIEW ON CLIENT, REMOVE BROWSER TAB AND RELOAD BROWSER

	console.log("View._removeView    viewObject: " + dojo.toJson(viewObject));
	console.dir({viewObject:viewObject});

	if ( ! Agua.removeView(viewObject) ) {
		console.log("View._removeView    Could not remove view: " + viewObject.view);
		return;
	}

	//var previousView = Agua.getPreviousView(viewObject);
	//console.log("View._removeView    previousView: ");
	//console.dir({previousView:previousView});
	
},
_remoteRemoveView : function (viewObject) {	
// REMOVE VIEW ON REMOTE
	console.log("View._remoteRemoveView    viewObject:");
	console.dir({viewObject:viewObject});

	var putData 		= 	dojo.clone(viewObject);
	putData.mode 		= 	"removeView";
	putData.module 		= 	"View";
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');

	var thisObject 		= this;
	var url 			= this.url;
	var callback 		= function (response) {
		console.log("View._remoteRemoveView    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("View._remoteRemoveView    Error removing view");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleRemoveView : function (response, viewObject) {
	console.log("View._handleRemoveView    response: ");
	console.dir({response:response});
	console.log("View._handleRemoveView    viewObject: ");
	console.dir({viewObject:viewObject});
	
	if ( response ) {

	console.log("View._handleRemoveView    HERE 1 XXX");
	//if ( response.status == 'none' ) {
		this.polling = false;
		if ( this.standby._textNode )
			this.standby._setTextAttr("");

	console.log("View._handleRemoveView    HERE 2");
		this.standby.hide();

	console.log("View._handleRemoveView    HERE 3");
		this.displayReady();

	console.log("View._handleRemoveView    HERE 4");
		
		var previousView = Agua.getPreviousView(viewObject);
		console.log("View._handleRemoveView    previousView: ");
		console.dir({previousView:previousView});
		
		// REMOVE BROWSER
		console.log("View._handleRemoveView    Doing this.removeBrowser()");
		var browserObject = this.getBrowser(viewObject.project, viewObject.view);
		console.log("View._handleRemoveView    browserObject: ");
		console.dir({browserObject:browserObject});
		this.removeBrowser(browserObject.browser, viewObject.project, viewObject.view);
		
		// SET VIEW PROJECT COMBO
		console.log("View._handleRemoveView    DOING this.setViewProjectCombo(previousView.project, previousView.view)");
		this.setViewProjectCombo(previousView.project, previousView.view);

		//// RELOAD BROWSER
		//console.log("View._handleRemoveView    Doing this.reloadBrowser()");
		//this.reloadBrowser(previousView.project, previousView.view);

		Agua.toastInfo("Removed view: " + viewObject.view);
	}
	else if ( response.error ) {
		this.polling = false;
		this.standby.hide();
		this.displayReady();
		console.log("View.addView    Error on remote. Response: ");
		console.dir({response:response});
	}
	else {
		console.log("View._delayedPoll    Doing this._delayedPoll(dojo.clone(viewObject), this._handleRemoveView, message)");
		var message = "View._delayedPoll    addView";
		this._delayedPoll(dojo.clone(viewObject), dojo.hitch(this,"_handleRemoveView"), message);
	}
},
// ADD VIEW FEATURE
addViewFeature : function () {
	console.log("View.addViewFeature    plugins.view.View.addViewFeature()");
	if ( ! this.getFeature()	)	return;

	// SKIP IF ALREADY BUSY
	if ( this.polling == true ) {
		console.log("View.addViewFeature    this.polling IS TRUE. Returning");
		return;
	}
	this.polling = true;

	var project		=	this.getProject();
	var view 		= 	this.getView();
	var feature 	= 	this.getFeature();

	if ( Agua.hasViewFeature(project, view, feature) ) {
		console.log("View.addViewFeature    Feature already present. Returning");
		this.polling = false;
		return;
	}

	// DISPLAY LOADING
	this.displayLoading();

	// DISPLAY STANDBY
	this.showStandby("Adding feature '" + feature + "' <br>to view '" + project + "." + view + "'");

	// PREPARE FEATURE TRACK OBJECT
	var featureObject = new Object;
	// VIEW INFO
	featureObject.project 		= project;
	featureObject.view 			= view;
	// SOURCE FEATURE INFO
	featureObject.feature 		= feature;
	featureObject.sourceproject = this.getFeatureProject();
	featureObject.sourceworkflow = this.getFeatureWorkflow();
	featureObject.species 		= this.getFeatureSpecies();
	featureObject.build 		= this.getFeatureBuild();
	
	if ( Agua.hasViewFeature == true ) {
		console.log("View.addViewFeature    hasViewFeature is TRUE");
		return;	
	}

	// ADD ON CLIENT AND REMOTE
	this._addViewFeature(dojo.clone(featureObject));
	this._remoteAddViewFeature(dojo.clone(featureObject));

	// SET POLL
	console.log("View.addViewFeature    Doing this._delayedPoll()");
	var message = "View._delayedPoll    addViewFeature";
	this._delayedPoll(dojo.clone(featureObject), dojo.hitch(this,"_handleAddViewFeature"), message);
},
_addViewFeature : function (featureObject) {
	console.log("View._addViewFeature    featureObject: ");
	console.dir({featureObject:featureObject});

	// ADD FEATURE TO VIEW
	if ( ! Agua._addViewFeature(featureObject) ) {
		console.log("View._addViewFeature    Agua._addViewFeature FAILED");
		Agua.toastError("Failed to add feature to local data: " + featureObject.feature);
	}
},
_remoteAddViewFeature : function ( featureObject) {
	console.log("View._remoteAddViewFeature    featureObject:");
	console.dir({featureObject:featureObject});

	// SET USER INFO AND MODE
	var putData 		= 	dojo.clone(featureObject);
	putData.username 	= 	Agua.cookie('username');
	putData.sessionid 	= 	Agua.cookie('sessionid');
	putData.mode 		= 	"addViewFeature";
	putData.module 		= 	"View";

	var url 			= 	this.url;
	var callback 		= 	function (response) {
		console.log("View._remoteAddViewFeature    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("View._remoteAddViewFeature    Error adding viewFeature");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleAddViewFeature : function (response, featureObject) {
	console.log("View._handleAddViewFeature    response: ");
	console.dir({response:response});
	console.log("View._handleAddViewFeature    featureObject: ");
	console.dir({featureObject:featureObject});
		
	if ( response.status == 'ready' ) {
		this.polling = false;
		this.standby._setTextAttr("");
		this.standby.hide();
		this.displayReady();

		// SET VIEW COMBO
		console.log("View._handleAddViewFeature    Doing this.setViewCombo(featureObject.project, featureObject.view)")
		this.setViewCombo(featureObject.project, featureObject.view);
	
		// RELOAD BROWSER
		console.log("View._handleAddViewFeature    Doing this.reloadBrowser(featureObject.project, featureObject.view)")
		this.reloadBrowser(featureObject.project, featureObject.view);
	
		Agua.toastInfo("Added feature: " + featureObject.feature);
	}
	else if ( response.error ) {
		this.polling = false;
		this.standby.hide();
		this.displayReady();
		console.log("View.handleAddViewFeature    Error on remote. Response: ");
		console.dir({response:response});
	}
	else {
		console.log("View._handleAddViewFeature    Doing this._delayedPollAddViewFeature()");
		var message = "View._delayedPoll    handleAddViewFeature";
		this._delayedPoll(dojo.clone(featureObject), dojo.hitch(this,"_handleAddViewFeature"), message);
	}
},
// REMOVE VIEW FEATURE
removeViewFeature : function () {
	console.log("View.removeViewFeature    plugins.view.View.removeViewFeature()");
	if ( ! this.getViewFeature()	)	return;

	// SKIP IF ALREADY BUSY
	if ( this.polling == true ) {
		console.log("View.addViewFeature    this.polling IS TRUE. Returning");
		return;
	}
	this.polling = true;

	var project		=	this.getProject();
	var view 		= 	this.getView();
	var feature 	= 	this.getViewFeature();

	if ( ! Agua.hasViewFeature(project, view, feature) ) {
		console.log("View.removeViewFeature    Feature NOT present. Returning");
		this.polling = false;
		return;
	}

	// DISPLAY STANDBY
	this.showStandby("Removing feature '" + feature + "' <br>from view '" + project + "." + view + "'");

	// DISPLAY LOADING
	this.displayLoading();

	// REMOVE FROM CLIENT AND REMOTE
	var featureObject 			= new Object;
	featureObject.project 		= this.getProject();
	featureObject.view 			= this.getView();
	featureObject.feature 		= this.getViewFeature();
	featureObject.species		= this.getFeatureSpecies();
	featureObject.build 		= this.getFeatureBuild();
	featureObject.username 		= Agua.cookie('username');
	featureObject.sessionid 	= Agua.cookie('sessionid');
	featureObject.mode 			= "removeViewFeature";
	featureObject.module 		= "View";
	console.log("View.removeViewFeature    featureObject: " + dojo.toJson(featureObject, true));

	// ADD ON CLIENT AND REMOTE
	this._removeViewFeature(dojo.clone(featureObject));
	this._remoteRemoveViewFeature(dojo.clone(featureObject));

	// SET POLL
	console.log("View.addViewFeature    Doing this._delayedPoll()");
	var message = "View._delayedPoll    addViewFeature";
	this._delayedPoll(dojo.clone(featureObject), dojo.hitch(this,"_handleRemoveViewFeature"), message);	
},
_removeViewFeature : function (featureObject) {
	console.log("View._removeViewFeature    featureObject: " + dojo.toJson(featureObject));

	// REMOVE FEATURE FROM VIEW
	console.log("View._removeViewFeature    Doing Agua._removeViewFeature()");
	if ( ! Agua._removeViewFeature(featureObject) ) {
		console.log("View._removeViewFeature    Agua._removeViewFeature FAILED");
	Agua.toastError("Failed to remove feature from local data: " + featureObject.feature);
	}
},
_remoteRemoveViewFeature : function (featureObject) {
	console.log("View._remoteRemoveViewFeature    featureObject:");
	console.dir({featureObject:featureObject});

	// SET USER INFO AND MODE
	var putData 		= dojo.clone(featureObject);
	putData.username 	= Agua.cookie('username');
	putData.sessionid 	= Agua.cookie('sessionid');
	putData.mode 		= "removeViewFeature";
	putData.module 		= "View";

	var url 			= this.url;
	var callback 		= function (response) {
		console.log("View._remoteRemoveViewFeature    response: ");
		console.dir({response:response});
		if ( response.error ) {
			thisObject.standby.hide();
			console.log("View._remoteRemoveViewFeature    Error removing viewFeature");
			Agua.toast(response);
		}
	};
	
	// DO CALL
	this.doPut({ url: url, query: putData, callback: callback, doToast: false });
},
_handleRemoveViewFeature : function (response, featureObject) {
	console.log("View._handleRemoveViewFeature    response: ");
	console.dir({response:response});
	console.log("View._handleRemoveViewFeature    featureObject: ");
	console.dir({featureObject:featureObject});
		
	if ( response.status == 'ready' ) {
		this.polling = false;
		this.standby._setTextAttr("");
		this.standby.hide();
		this.displayReady();

		// SET VIEW COMBO
		console.log("View._handleRemoveViewFeature    DOING this.setViewCombo(" + featureObject.project + ", " + featureObject.view + ")");
			this.setViewCombo(featureObject.project, featureObject.view);
	
		// RELOAD BROWSER
		console.log("View._handleRemoveViewFeature    DOING this.reloadBrowser(" + featureObject.project + ", " + featureObject.view + ")");
		this.reloadBrowser(featureObject.project, featureObject.view);
	
		Agua.toastInfo("Removed feature: " + featureObject.feature);
	}
	else if ( response.error ) {
		this.polling = false;
		this.standby.hide();
		this.displayReady();
		console.log("View.handleRemoveViewFeature    Error on remote. Response: ");
		console.dir({response:response});
	}
	else {
		console.log("View._handleRemoveViewFeature    Doing this._handleRemoveViewFeature()");
		var message = "View._delayedPoll    handleRemoveViewFeature";
		this._delayedPoll(dojo.clone(featureObject), dojo.hitch(this,"_handleRemoveViewFeature"), message);
	}
},
// SET COMPONENTS
displayLoading : function () {
	dojo.removeClass(this.statusDisplay, "statusReady");
	dojo.addClass(this.statusDisplay, "statusLoading");
},
displayReady : function () {
	dojo.removeClass(this.statusDisplay, "statusLoading");
	dojo.addClass(this.statusDisplay, "statusReady");
},
onStartRemote : function () {
// 4. SHOW ANIMATED 'COPYING' DIALOGUE
	console.log("View.onStartRemote    caller: " + this.onStartRemote.caller.nom);
	console.dir({caller:this.onStartRemote.caller});
	console.log("View.onStartRemote    this.standby: " + this.standby);

	// SHOW STANDBY 
	this.standby.show();

	// DISPLAY LOADING
	this.displayLoading();
},
pollRemote: function(timer) {
// 5. POLL SERVER FOR STATUS AND WAIT UNTIL COMPLETE
	console.log("View.pollRemote    timer: " + timer);
	console.dir({timer:timer});
	if ( timer.url == null )	return;
	if ( timer.query == null ) 	return;

	var thisObject = this;
	var completed = false;
	dojo.xhrPut(
		{
			url: timer.url,
			contentType: "text",
			//preventCache : true,
			putData: dojo.toJson(timer.query),
			handleAs: "json-comment-optional",
			sync: true,
			handle : function (response) {

				console.log("View.pollRemote    response: " + dojo.toJson(response, true));
				if ( response.status == 'ready'
					|| response.status == 'error'
					|| response.error != null ) {
					console.log("View.pollRemote    setting completed to TRUE");
					completed = true;
					timer.response = response;
				}
			}
		}
	);
	
	console.log("View.pollRemote    Returning completed: " + completed);
	return completed;
},
onEndRemote : function () {
// 6. IF COPY IS COMPLETED, RELOAD THE PANE TO
// DISPLAY THE NEW FILE SYSTEM
	console.log("View.onEndRemote    plugins.view.View.onEndRemote()");

	// HIDE STANDBY
	this.standby.hide();

	// DISPLAY READY
	this.displayReady();

	console.log("View.onEndRemote    Doing this.callback()");
	console.dir({callback:this.callback});
	
	if ( this.callback )	this.callback();
},
// STANDBY
setStandby : function () {
	console.log("View.setStandby    _GroupDragPane.setStandby()");
	if ( this.standby != null )	return this.standby;
	
	var id = dijit.getUniqueId("dojox_widget_Standby");
	this.standby = new dojox.widget.Standby (
		{
			target: this.rightPane.domNode,
			//onClick: "reload",
			centerIndicator : "text",
			text: "Loading",
			id : id
			//, url: "plugins/core/images/agua-biwave-24.png"
		}
	);
	document.body.appendChild(this.standby.domNode);
	dojo.addClass(this.standby._textNode, "viewStandby");
	console.log("View.setStandby    this.standby: ");
	console.dir({this_standby:this.standby});
	
	return this.standby;
},
showStandby : function (message) {
	// SET STANDBY TEXT
	console.log("View.showStandby    message: " + message);
	this.standby._setTextAttr(message);
	this.standby.show();
},	
hideStandby : function () {
	// SET STANDBY TEXT
	this.standby._setTextAttr("");
	this.standby.hide();
},	
// BROWSER METHODS
loadBrowser : function (projectName, viewName) {
	console.log("View.loadBrowser      PASSED projectName: " + projectName);
	console.log("View.loadBrowser      PASSED viewName: " + viewName);

	if ( projectName == null )	projectName = this.getProject();
	if ( viewName == null )		viewName = this.getView();
	console.log("View.loadBrowser      projectName: " + projectName);
	console.log("View.loadBrowser      viewName: " + viewName);

	// SELECT VIEW TAB IF EXISTS
	if ( this.selectBrowser(projectName, viewName) )	return;
	
	var username = Agua.cookie('username');
	var refseqfile = this.getRefseqfile(username, projectName, viewName);
	var trackinfofile = this.getTrackinfofile(username, projectName, viewName);
	console.log("View.loadBrowser      refseqfile: " + refseqfile);
	console.log("View.loadBrowser      trackinfofile: " + trackinfofile);

	// LOAD refSeqs AND trackInfo JSON FILES
	this.loadEval(trackinfofile);
	this.loadEval(refseqfile);
	if ( refSeqs == null ) {
		console.log("View.loadBrowser      refSeqs is null. Returning");
		return;
	}
	if ( trackInfo == null ) {
		console.log("View.loadBrowser      trackInfo is null. Returning");
		return;
	}
	console.log("View.loadBrowser      refSeqs: ");
	console.dir({refSeqs:refSeqs});

	// CHECK INPUTS
	if ( projectName == null || viewName == null ) {
		console.log("View.loadBrowser    One of the required inputs (projectName, viewName) is null. Returning");
		return;
	}

	var viewObject = Agua.getViewObject(projectName, viewName);
	console.log("View.loadBrowser      viewObject: ");
	console.dir({viewObject:viewObject});
	if ( ! viewObject )	{
		console.log("View.loadBrowser      viewObject is not defined. Returning");
		return;
	}
	
	var trackList	=	viewObject.tracklist;
	var speciesName	=	viewObject.species;
	var buildName	=	viewObject.build;
	var username = Agua.cookie('username');

	// SET LOCATION OBJECT:
	// {"name":"chr1","start":"99,711,844","stop":"149,561,968"}
	// AND LOCATION STRING:
	// "chr1:99,711,844 .. 149,561,968"
	var locationObject = this.getLocationObject(viewObject);
	var startStop = locationObject.start + "..." + locationObject.stop;
	var location	=	locationObject.name + ":" + startStop;
	console.log("View.loadBrowser      location: " + location);
	
	// GET UNIQUE ID FOR THIS MENU TO BE USED IN DND SOURCE LATER
	var objectName = "plugins.view.View.jbrowse.Browser";
	var browserId = dijit.getUniqueId(objectName.replace(/\./g,"_"));
	
	// SET LOADING FLAG TO STOP PREMATURE updateViewLocation/ViewTracklist
	this.loading = true;
	
	var b = new plugins.view.jbrowse.js.Browser({
		parentWidget 	: this,
		viewObject	 	: viewObject,
		speciesName		: speciesName,
		buildName  		: buildName,
		species    		: speciesName,
		build      		: buildName,
		refSeqs			: refSeqs,
		trackData		: trackInfo,
		baseUrl 		: this.baseUrl,
		dataRoot 		: this.baseUrl + "/users/" + username + "/" + projectName + "/" + viewName+ "/",
		
		locationObject 	: locationObject,
		location 		: location,
		
		//browserRoot : this.baseUrl,
		browserRoot 	: this.browserRoot,
		//defaultLocation : "chr2:10000000..100000000",
		//defaultTracks : "vegaGene,CCDS", 
		trackList 		: trackList,
		tracks 			: trackList,
		attachWidget 	: this.rightPane
	});

	// ADD TO this.browsers ARRAY		
	this.addBrowser(b, projectName, viewName);
	console.dir({browser:b});

	//// SET NAVIGATION BOX VALUES
	//b.chromList.value = viewObject.chromosome;
	//b.locationBox.value = viewObject.start  + "..." + viewObject.stop;

	console.log("View.loadBrowser    XXXXXXX END OF LOADING XXXXXX");
	console.log("View.loadBrowser    this.loading: " + this.loading);

	// CONNECT TO browser.mainTab DESTROY TO DO this.removeBrowser
	dojo.connect(b.mainTab, "destroy", dojo.hitch(this, "removeBrowserObject", b, projectName, viewName));

	console.log("View.loadBrowser      XXXXXXX END OF NAVIGATION XXXXXX");
	this.loading = false;
	console.log("View.loadBrowser    SET this.loading TO : " + this.loading);
	
}, // 	loadBrowser 
getLocationObject : function (viewObject) {
// DEFAULT RANGE IS LEFT TENTH OF FIRST CHROMOSOME
	console.log("View.getLocationObject    viewObject:");
	console.dir({viewObject:viewObject});
	
	var locationObject = new Object;

	if ( ! viewObject.chromosome ) {
		viewObject.chromosome	= 	refSeqs[0].name;
		viewObject.start 		= 	0;
		viewObject.stop 		= 	(refSeqs[0].end / 10);
	}	
	
	locationObject.name		= 	viewObject.chromosome;
	locationObject.start	=	parseInt(viewObject.start);
	locationObject.stop		=	parseInt(viewObject.stop);

	console.log("View.getLocationObject    Returning locationObject:");
	console.dir({locationObject:locationObject});

	return locationObject;	
},
reloadBrowser : function (projectName, viewName) {
	console.log("View.reloadBrowser      projectName: " + projectName);
	console.log("View.reloadBrowser      viewName: " + viewName);

	var browser = this.getBrowser(projectName, viewName); 
	if ( browser != null )
	{
		// REMOVE EXISTING BROWSER FOR THIS VIEW
		console.log("View.reloadBrowser    BEFORE this.removeBrowser(projectName, workflow, viewName)");
		this.removeBrowser(browser.browser, projectName, viewName);
		console.log("View.reloadBrowser    AFTER this.removeBrowser(projectName, workflow, viewName)");
	}
	this.loadBrowser(projectName, viewName);

	console.log("View.reloadBrowser    AFTER loadBrowser");

}, // 	reloadBrowser 
selectBrowser : function (projectName, viewName) {
// FOR EACH NEWLY OPENED VIEW TAB, THE ASSOCIATED BROWSER 
// OBJECT IS ADDED TO this.browsers ARRAY
	//console.log("View.selectBrowser    plugins.view.View.selectBrowser(projectName, viewName)");
	console.log("View.selectBrowser    projectName: " + projectName);
	console.log("View.selectBrowser    viewName: " + viewName);

	var browserObject = this.getBrowser(projectName, viewName);
	console.log("View.selectBrowser    browserObject: " + browserObject);

	if ( browserObject == null )	return;
	var browser = browserObject.browser;

	//console.log("View.selectBrowser    BEFORE selectChild(browser.mainTab)");
	this.rightPane.selectChild(browser.mainTab);
	//console.log("View.selectBrowser    AFTER selectChild(browser.mainTab)");
	return 1;
},
getBrowser : function (projectName, viewName) {
	//console.log("View.getBrowser    projectName: " + projectName);
	//console.log("View.getBrowser    viewName: " + viewName);

	var index = this.getBrowserIndex(projectName, viewName);
	console.log("View.selectBrowser    index: " + index);
	if ( index == null )	return;

	return this.browsers[index];
},
addBrowser : function(browser, projectName, viewName) {
// FOR EACH NEWLY OPENED VIEW TAB, THE ASSOCIATED BROWSER 
// OBJECT IS ADDED TO this.browsers ARRAY
	//console.log("View.addBrowser    plugins.view.View.addBrowser(browser, project, workflow, view)");
	console.log("View.addBrowser    browser: " + browser);
	console.log("View.addBrowser    projectName: " + projectName);
	console.log("View.addBrowser    viewName: " + viewName);
	console.log("View.addBrowser    viewId: " + this.id);
	
	var browserObject = {
		browser : 	browser,
		project: 	projectName,
		view:		viewName,
		viewid:     this.id
	};

	var success = this._addObjectToArray(this.browsers, browserObject, ["browser", "project", "view", "viewid"]);
	console.log("View.addBrowser    success: " + success);

	//// ADD TO TABS
	//this.rightPane.addChild(browserObject.browser.mainTab);
	//this.rightPane.selectChild(browserObject.browser.mainTab);
	
	return success;	
},
isBrowser : function (projectName, viewName) {
	console.log("View.isBrowser    projectName: " + projectName);
	console.log("View.isBrowser    viewName: " + viewName);

	if ( this.getBrowserIndex(projectName, viewName) != null )	{
		console.log("View.isBrowser    Returning 1");
		return 1;
	}
	else {
		console.log("View.isBrowser    Returning 0");
		return 0;
	}	
},
getBrowserIndex : function (projectName, viewName) {
	console.log("View.getBrowserIndex    projectName: " + projectName);
	console.log("View.getBrowserIndex    viewName: " + viewName);
	console.log("View.getBrowserIndex    this.browsers: ");
	console.dir({this_browsers:this.browsers});

	var browserObject = {
		project	: 	projectName,
		view	:	viewName,
		viewid  :   this.id
	};

	var index = this._getIndexInArray(this.browsers, { project: projectName, view: viewName }, [ "project", "view", "viewid" ])
	console.log("View.getBrowserIndex    index: " + index);	
	
	return index;
},
removeBrowser : function (browser, projectName, viewName) {
// WHEN A VIEW TAB IS CLOSED, REMOVE ITS ASSOCIATED
// browser OBJECT FROM this.browsers AND DESTROY IT
	console.log("View.removeBrowser    plugins.viewName.View.removeBrowser(browser, projectName, viewName)");
	console.log("View.removeBrowser    browser: " + browser);
	console.log("View.removeBrowser    projectName: " + projectName);
	console.log("View.removeBrowser    viewName: " + viewName);
	
	this.removeBrowserTab(browser);
	var success = this.removeBrowserObject(browser, projectName, viewName);
	console.log("View.removeBrowser    success: " + success);

},
removeBrowserObject : function (browser, projectName, viewName) {
	console.log("View.removeBrowserObject    caller: " + this.removeBrowserObject.caller.nom);
	console.log("View.removeBrowserObject    browser: " + browser);
	console.dir({browser:browser});
	console.log("View.removeBrowserObject    projectName: " + projectName);
	console.log("View.removeBrowserObject    viewName: " + viewName);
	console.log("View.removeBrowserObject    BEFORE this.browsers: ");
	console.dir({this_browsers:this.browsers});

	var browserObject = {
		browser : 	browser,
		project: 	projectName,
		view:		viewName
	};
	console.log("View.removeBrowserObject    browserObject: ");
	console.dir({browserObject:browserObject});

	console.log("View.removeBrowserObject    BEFORE this.browsers.length: " + this.browsers.length);
	var success = this._removeObjectFromArray(this.browsers, browserObject, ["browser", "project", "view"]);
	console.log("View.removeBrowserObject    success: " + success);
	console.log("View.removeBrowserObject    AFTER this.browsers: ");
	console.dir({this_browsers:this.browsers});
	console.log("View.removeBrowserObject    AFTER this.browsers.length: " + this.browsers.length);

	return success;	
},
removeBrowserTab : function (browser, projectName, viewName) {
	// REMOVE BROWSER TAB FROM PANE
	console.log("View.removeBrowserTab    browser:");
	console.dir({browser:browser});
	
	this.rightPane.removeChild(browser.mainTab);
	console.log("View.removeBrowserTab    AFTER removeChild(browser.mainTab)");

	return true;
},
// FIRE COMBO HANDLERS
fireViewProjectCombo : function() {
	console.log("View.fireViewProjectCombo    viewProjectCombo._onchange");
	var projectName = this.viewProjectCombo.get('value');
	this.setViewCombo(projectName);
},
fireViewCombo : function () {
// ONCHANGE IN VIEW COMBO FIRED
	if ( ! this.viewComboFired == true )
	{
		this.viewComboFired = true;
	}
	else {
		console.log("View.fireViewCombo    plugins.view.View.fireViewCombo()");
	
		var projectName = this.getProject();
		var viewName = this.getView();
		console.log("View.fireViewCombo    projectName: " + projectName);
		console.log("View.fireViewCombo    viewName: " + viewName);
		this.setSpeciesLabel(projectName, viewName);
	
		this.loadBrowser(projectName, viewName);
	}
},
fireFeatureProjectCombo : function() {
	if ( ! this.featureProjectComboFired == true )
	{
		this.featureProjectComboFired = true;
	}
	else {
		console.log("View.fireFeatureProjectCombo    plugins.view.View.fireFeatureProjectCombo()");
		var projectName = this.featureProjectCombo.get('value');
		this.setWorkflowCombo(projectName);
	}
},
fireWorkflowCombo : function() {
	if ( ! this.workflowComboFired == true )
	{
		this.workflowComboFired = true;
	}
	else {
		console.log("View.fireWorkflowCombo    plugins.view.View.fireWorkflowCombo()");
		var projectName = this.featureProjectCombo.get('value');
		var workflowName = this.workflowCombo.get('value');
		this.setSpeciesCombo(projectName, workflowName);
	}
},
fireSpeciesCombo : function () {
	if ( ! this.speciesComboFired == true )
	{
		console.log("View.fireSpeciesCombo    FIRST FIRE");
		this.speciesComboFired = true;
	}
	else {
		console.log("View.fireSpeciesCombo    plugins.view.View.fireSpeciesCombo()");
		var projectName = this.viewProjectCombo.get('value');
		var workflowName = this.workflowCombo.get('value');
		var speciesName = this.getSpecies();
		var buildName = this.getBuild();
		console.log("View.fireSpeciesCombo    projectName: " + projectName);
		console.log("View.fireSpeciesCombo    workflowName: " + workflowName);
		console.log("View.fireSpeciesCombo    speciesName: " + speciesName);
		console.log("View.fireSpeciesCombo    buildName: " + buildName);
		console.log("View.fireSpeciesCombo    this.setFeatureCombo(" + projectName + ", " + workflowName + ", " + speciesName + ", " + buildName + ")");
		
		if ( speciesName == null || buildName == null )
		{
			console.log("View.fireSpeciesCombo    speciesName and/or buildName is null. Returning.");
			return;
		}
		
		this.setFeatureCombo(projectName, workflowName, speciesName, buildName);
	}
},
destroyRecursive : function () {
	console.log("View.destroyRecursive    this.mainTab: ");
	console.dir({this_mainTab:this.mainTab});
	if ( Agua && Agua.tabs )
		Agua.tabs.removeChild(this.mainTab);
	
	this.inherited(arguments);
}

}); // end of plugins.view.View

