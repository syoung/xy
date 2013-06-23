dojo.provide("plugins.core.Common.ComboBox");

/* SUMMARY: THIS CLASS IS INHERITED BY Common.js AND CONTAINS 
	
	COMBOBOX METHODS  
*/

dojo.declare( "plugins.core.Common.ComboBox",	[  ], {

///////}}}
// COMBOBOX METHODS
setUsernameCombo : function () {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: Agua.sharedprojects DATA OBJECT
//	OUTPUTS:	ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedProjectCombo
	//console.log("  Common.ComboBox.setUsernameCombo    plugins.core.Common.setUsernameCombo()");
	var usernames = Agua.getSharedUsernames();
	//console.log("  Common.ComboBox.setUsernameCombo    usernames: " + dojo.toJson(usernames));

	// RETURN IF projects NOT DEFINED
	if ( usernames == null || usernames.length == 0 )
	{
		//console.log("  Common.ComboBox.setUsernameCombo    usernames not defined. Returning.");
		return;
	}

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in usernames )
	{
		data.items[i] = { name: usernames[i]	};
	}
	//console.log("  Common.ComboBox.setUsernameCombo    store data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );
	//console.log("   Common.setUsernameCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.usernameCombo.store = store;	
	
	// START UP AND SET VALUE
	this.usernameCombo.startup();
	this.usernameCombo.set('value', usernames[0]);			
},
setSharedProjectCombo : function (username, projectName, workflowName) {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: USERNAME, OPTIONAL PROJECT NAME AND WORKFLOW NAME
//	OUTPUTS: ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedWorkflowCombo

	//console.log("  Common.ComboBox.setSharedProjectCombo    plugins.report.Workflow.setSharedProjectCombo(username, project, workflow)");

	var projects = Agua.getSharedProjectsByUsername(username);
	if ( projects == null )
	{
		//console.log("   Common.setSharedProjectCombo    projects is null. Returning");
		return;
	}
	//console.log("  Common.ComboBox.setSharedProjectCombo    projects: " + dojo.toJson(projects));
	
	var projectNames = this.hashArrayKeyToArray(projects, "name");
	projectNames = this.uniqueValues(projectNames);
	//console.log("  Common.ComboBox.setSharedProjectCombo    projectNames: " + dojo.toJson(projectNames));
	
	// RETURN IF projects NOT DEFINED
	if ( projectNames == null || projectNames.length == 0 )
	{
		//console.log("  Common.ComboBox.setSharedProjectCombo    projectNames not defined. Returning.");
		return;
	}

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in projectNames )
	{
		data.items[i] = { name: projectNames[i]	};
	}
	//console.log("  Common.ComboBox.setSharedProjectCombo    store data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );
	//console.log("  Common.ComboBox.setSharedProjectCombo    store: " + dojo.toJson(store));

	// ADD STORE TO USERNAMES COMBO
	this.projectCombo.store = store;	
	
	// START UP AND SET VALUE
	this.projectCombo.startup();
	this.projectCombo.set('value', projectNames[0]);	
},
setSharedWorkflowCombo : function (username, projectName, workflowName) {
//	POPULATE COMBOBOX AND SET SELECTED ITEM
//	INPUTS: USERNAME, OPTIONAL PROJECT NAME AND WORKFLOW NAME
//	OUTPUTS: ARRAY OF USERNAMES IN COMBO BOX, ONCLICK CALL TO setSharedWorkflowCombo

	console.log("  Common.ComboBox.setSharedWorkflowCombo    plugins.report.Workflow.setSharedWorkflowCombo(username, project, workflow)");
	console.log("  Common.ComboBox.setSharedWorkflowCombo    projectName: " + projectName);
				
	if ( projectName == null )	projectName = this.projectCombo.get('value');
	console.log("  Common.ComboBox.setSharedWorkflowCombo    AFTER projectName: " + projectName);

	var workflows = Agua.getSharedWorkflowsByProject(username, projectName);
	if ( workflows == null )
	{
		console.log("  Common.ComboBox.setSharedWorkflowCombo    workflows is null. Returning");
		return;
	}
	console.log("  Common.ComboBox.setSharedWorkflowCombo    workflows: ");
	console.dir({workflows:workflows});
	
	var workflowNames = this.hashArrayKeyToArray(workflows, "name");
	workflowNames = this.uniqueValues(workflowNames);
	console.log("  Common.ComboBox.setSharedWorkflowCombo    workflowNames: " + dojo.toJson(workflowNames));
	
	// RETURN IF workflows NOT DEFINED
	if ( workflowNames == null || workflowNames.length == 0 )
	{
		console.log("  Common.ComboBox.setSharedWorkflowCombo    workflowNames not defined. Returning.");
		return;
	}

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in workflowNames )
	{
		data.items[i] = { name: workflowNames[i]	};
	}

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );

	// ADD STORE TO USERNAMES COMBO
	this.workflowCombo.store = store;	
	
	// START UP AND SET VALUE
	this.workflowCombo.startup();
	this.workflowCombo.set('value', workflowNames[0]);
},
setProjectCombo : function (project, workflow) {
//	INPUT: (OPTIONAL) project, workflow NAMES
//	OUTPUT:	POPULATE COMBOBOX AND SET SELECTED ITEM

	////console.log("  Common.ComboBox.setProjectCombo    plugins.report.Template.Common.setProjectCombo(project,workflow)");
	////console.log("  Common.ComboBox.setProjectCombo    project: " + project);
	////console.log("  Common.ComboBox.setProjectCombo    workflow: " + workflow);

	var projectNames = Agua.getProjectNames();
	////console.log("  Common.ComboBox.setProjectCombo    projectNames: " + dojo.toJson(projectNames));

	// RETURN IF projects NOT DEFINED
	if ( ! projectNames )
	{
		//console.log("  Common.ComboBox.setProjectCombo    projectNames not defined. Returning.");
		return;
	}
	////console.log("  Common.ComboBox.setProjectCombo    projects: " + dojo.toJson(projects));

	// SET PROJECT IF NOT DEFINED TO FIRST ENTRY IN projects
	if ( project == null || ! project)	project = projectNames[0];
	
	// DO DATA ARRAY
	var data = {identifier: "name", items: []};
	for ( var i in projectNames )
	{
		data.items[i] = { name: projectNames[i]	};
	}
	////console.log("  Common.ComboBox.setProjectCombo    store data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( {	data: data	} );

	//// GET PROJECT COMBO WIDGET
	var projectCombo = this.projectCombo;
	if ( projectCombo == null )
	{
		//console.log("  Common.ComboBox.setProjectCombo    projectCombo is null. Returning.");
		return;
	}
			
	projectCombo.store = store;	
	////console.log("  Common.ComboBox.setProjectCombo    project: " + project);
	
	// START UP AND SET VALUE
	//projectCombo.startup();
	//console.log("  Common.ComboBox.setProjectCombo    projectCombo.set('value', " + project + ")");
	projectCombo.set('value', project);			
},
setWorkflowCombo : function (project, workflow) {
// SET THE workflow COMBOBOX

	//console.log("  Common.ComboBox.setWorkflowCombo    plugins.workflow.Common.setWorkflowCombo(project, workflow)");

	if ( project == null || ! project )
	{
		//console.log("  Common.ComboBox.setWorkflowCombo    Project not defined. Returning.");
		return;
	}
	//console.log("  Common.ComboBox.setWorkflowCombo    project: " + project);
	//console.log("  Common.ComboBox.setWorkflowCombo    workflow: " + workflow);

	// CREATE THE DATA FOR A STORE		
	var workflows = Agua.getWorkflowsByProject(project);
	//console.log("  Common.ComboBox.setWorkflowCombo    project '" + project + "' workflows: " + dojo.toJson(workflows));

	console.log("  Common.ComboBox.setWorkflowCombo    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX DOING SORT workflows");
	workflows = this.sortHasharrayByKeys(workflows, ["number"]);
	console.log("  Common.ComboBox.setWorkflowCombo    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX AFTER SORT workflows:");
	console.dir({XXXXXXXXXXXXXXXXXworkflows:workflows});
	
	var workflowNames = this.hashArrayKeyToArray(workflows, "name");
	
	
	// RETURN IF workflows NOT DEFINED
	if ( ! workflowNames )
	{
		console.log("  Common.ComboBox.setWorkflowCombo    workflowNames not defined. Returning.");
		return;
	}		

	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in workflowNames )
	{
		data.items[i] = { name: workflowNames[i]	};
	}
	console.log("  Common.ComboBox.setWorkflowCombo    data: " + dojo.toJson(data));

	// CREATE store
	var store = new dojo.data.ItemFileReadStore( { data: data } );

	// GET WORKFLOW COMBO
	var workflowCombo = this.workflowCombo;
	if ( workflowCombo == null )
	{
		console.log("  Common.ComboBox.setworkflowCombo    workflowCombo is null. Returning.");
		return;
	}

	//console.log("  Common.ComboBox.setWorkflowCombo    workflowCombo: " + workflowCombo);
	workflowCombo.store = store;

	// START UP COMBO AND SET SELECTED VALUE TO FIRST ENTRY IN workflowNames IF NOT DEFINED 
	if ( workflow == null || ! workflow )	workflow = workflowNames[0];
	//console.log("  Common.ComboBox.setWorkflowCombo    workflow: " + workflow);

	workflowCombo.startup();
	workflowCombo.set('value', workflow);			
},
setReportCombo : function (project, workflow, report) {
// SET THE report COMBOBOX

	//console.log("  Common.ComboBox.setReportCombo    plugins.report.Common.setReportCombo(project, workflow, report)");
	//console.log("  Common.ComboBox.setReportCombo    project: " + project);
	//console.log("  Common.ComboBox.setReportCombo    workflow: " + workflow);
	//console.log("  Common.ComboBox.setReportCombo    report: " + report);

	if ( project == null || ! project )
	{
		console.log("  Common.ComboBox.setReportCombo    project not defined. Returning.");
		return;
	}
	if ( workflow == null || ! workflow )
	{
		console.log("  Common.ComboBox.setReportCombo    workflow not defined. Returning.");
		return;
	}
	//console.log("  Common.ComboBox.setReportCombo    project: " + project);
	//console.log("  Common.ComboBox.setReportCombo    workflow: " + workflow);
	//console.log("  Common.ComboBox.setReportCombo    report: " + report);

	var reports = Agua.getReportsByWorkflow(project, workflow);
	if ( reports == null )	reports = [];
	console.log("  Common.ComboBox.setReportCombo    project " + project + " reports: " + dojo.toJson(reports));

	var reportNames = this.hashArrayKeyToArray(reports, "name");
	console.log("  Common.ComboBox.setReportCombo    reportNames: " + dojo.toJson(reportNames));
	
	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in reports )
	{
		data.items[i] = { name: reportNames[i]	};
	}
	console.log("  Common.ComboBox.setReportCombo    data: " + dojo.toJson(data));

	// CREATE store
	// http://docs.dojocampus.org/dojo/data/ItemFileWriteStore
	var store = new dojo.data.ItemFileReadStore( { data: data } );

	// GET WORKFLOW COMBO
	var reportCombo = this.reportCombo;
	if ( reportCombo == null )
	{
		console.log("  Common.ComboBox.setreportCombo    reportCombo is null. Returning.");
		return;
	}

	console.log("  Common.ComboBox.setReportCombo    reportCombo: " + reportCombo);
	reportCombo.store = store;

	// GET USER INPUT WORKFLOW
	var snpReport = this;

	// START UP COMBO (?? NEEDED ??)
	reportCombo.startup();
	reportCombo.set('value', report);			
},
setViewCombo : function (projectName, viewName) {
// SET THE view COMBOBOX
	console.log("  Common.ComboBox.setViewCombo    projectName: " + projectName);
	console.log("  Common.ComboBox.setViewCombo    viewName: " + viewName);

	// SANITY CHECK
	if ( ! this.viewCombo )	return;
	if ( ! projectName )	return;

	var views = Agua.getViewNames(projectName);

	console.log("  Common.ComboBox.setViewCombo    BEFORE SORT views: ");
	console.dir({views: views});
	
	views.sort(this.sortNaturally);

	console.log("View.setViewCombo    AFTER SORT views: ");
	console.dir({views:views});

	//console.log("  Common.ComboBox.setViewCombo    projectName '" + projectName + "' views: " + dojo.toJson(views));
	
	// RETURN IF views NOT DEFINED
	if ( ! views || views.length == 0 )	views = [];
	//{
		//console.log("  Common.ComboBox.setViewCombo    views not defined. Returning.");
		//return;
		//Agua.addView({ project: projectName, name: "View1" });
		//views = Agua.getViewNames(projectName);
	//}		
	//console.log("  Common.ComboBox.setViewCombo    views: " + dojo.toJson(views));

	// SET view IF NOT DEFINED TO FIRST ENTRY IN views
	if ( viewName == null || ! viewName)
	{
		viewName = views[0];
	}
	//console.log("  Common.ComboBox.setViewCombo    viewName: " + viewName);
	
	// DO data FOR store
	var data = {identifier: "name", items: []};
	for ( var i in views )
	{
		data.items[i] = { name: views[i]	};
	}
	//console.log("  Common.ComboBox.setViewCombo    data: " + dojo.toJson(data));

	// CREATE store
	// http://docs.dojocampus.org/dojo/data/ItemFileWriteStore
	var store = new dojo.data.ItemFileReadStore( { data: data } );

	//console.log("  Common.ComboBox.setViewCombo    this.viewCombo: " + this.viewCombo);
	this.viewCombo.store = store;

	// START UP COMBO (?? NEEDED ??)
	this.viewCombo.startup();
	this.viewCombo.set('value', viewName);			
},
getSelectedValue : function (element) {
	var index = element.selectedIndex;
	//console.log("  Common.ComboBox.getSelectedValue    index: " + index);
	var value = element.options[index].text;
	//console.log("  Common.ComboBox.getSelectedValue    value: " + value);
	
	return value;
}



});