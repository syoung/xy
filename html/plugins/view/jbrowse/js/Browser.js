/**
 * Construct a new Browser object.
 * @class This class is the main interface between JBrowse and embedders
 * @constructor
 * @param params a dictionary with the following keys:<br>
 * <ul>
 * <li><code>containerID</code> - ID of the HTML element that contains the browser</li>
 * <li><code>refSeqs</code> - list of reference sequence information items (usually from refSeqs.js)</li>
 * <li><code>trackData</code> - list of track data items (usually from trackInfo.js)</li>
 * <li><code>dataRoot</code> - (optional) URL prefix for the data directory</li>
 * <li><code>browserRoot</code> - (optional) URL prefix for the browser code</li>
 * <li><code>tracks</code> - (optional) comma-delimited string containing initial list of tracks to view</li>
 * <li><code>location</code> - (optional) string describing the initial location</li>
 * <li><code>defaultTracks</code> - (optional) comma-delimited string containing initial list of tracks to view if there are no cookies and no "tracks" parameter</li>
 * <li><code>defaultLocation</code> - (optional) string describing the initial location if there are no cookies and no "location" parameter</li>
 * </ul>
 */

//var Browser = function(params) {

dojo.provide("plugins.view.jbrowse.js.Browser");

	dojo.require("dojo.dnd.Source");
	dojo.require("dojo.dnd.Moveable");
	dojo.require("dojo.dnd.Mover");
	dojo.require("dojo.dnd.move");
	dojo.require("dijit.layout.ContentPane");
	dojo.require("dijit.layout.BorderContainer");

dojo.require("plugins.core.Common");

dojo.declare( "plugins.view.jbrowse.js.Browser",
	[ dijit._Widget, dijit._Templated, plugins.core.Common ], {

//Path to the template of this widget. 
templatePath: dojo.moduleUrl("", "../plugins/view/templates/browser.html"),

// Calls dijit._Templated.widgetsInTemplate
widgetsInTemplate : true,

// CSS FILE FOR BUTTON STYLING
/* CHANGED */
cssFiles : [ "dojo-1.6.1rc2/dojox/layout/resources/ExpandoPane.css" ],

////}}}
constructor : function(args) {		
	//console.log("js.Browser.constructor	args:");
	//console.dir({args:args});
	
	// LOAD CSS
	this.loadCSS();
	
	// SET ARGS
	//this.attachWidget = Agua.tabs;
	this.viewObject = args.viewObject;
	this.parentWidget = args.parentWidget;
	this.projectName = args.projectName;
	this.viewName = args.viewName;
	this.speciesName = args.speciesName;
	this.buildName = args.buildName;

	this.location = args.location;
	this.locationObject = args.locationObject;

	this.params = args;
	this.refSeqs = args.refSeqs;
	this.trackData = args.trackData;
	this.deferredFunctions = [];

	this.tracks = args.tracks;
	this.trackList = args.trackList;
	//console.log("Browser.constructor	this.trackList: " + dojo.toJson(this.trackList));
	
	//this.baseUrl = args.baseUrl;

	this.dataRoot = args.dataRoot;
	this.dataRoot;
	if ("dataRoot" in args)
		dataRoot = args.dataRoot;
	else
		dataRoot = "";
		
	
	this.attachWidget = args.attachWidget;
	//console.log("Browser.constructor	this.attachWidget: " + this.attachWidget);
	
},

postCreate: function() {
	this.startup();
},

startup : function () {
	//console.log("Browser.startup	plugins.view.jbrowse.js.Browser.startup()");

	// SET UP THE ELEMENT OBJECTS AND THEIR VALUE FUNCTIONS
	this.inherited(arguments);

	// ADD THE PANE TO THE TAB CONTAINER
	this.attachWidget.addChild(this.mainTab);
	this.attachWidget.selectChild(this.mainTab);

	//console.log("Browser.startup	this.viewObject: " + dojo.toJson(this.viewObject));

	// SET TITLE
	this.mainTab.set('title', this.viewObject.project + "." + this.viewObject.view); 

	// SET SPECIES AND BUILD
	this.topPane.titleNode.innerHTML = this.firstLetterUpperCase(this.viewObject.species) + " (" + this.viewObject.build + ")";


// CHANGED IN THE REST OF THIS (startup) METHOD
// FROM:			TO:
// params.refSeqs	this.refSeqs
// params.trackDAta	this.trackData
// params.dataRoot	this.dataRoot

	this.deferredFunctions = [];

	var refSeqs = this.refSeqs;
	//console.log("plugins.view.js.jbrowse.Browser.startup    refSeqs: " + dojo.toJson(refSeqs));
	var trackData = this.trackData;
	var dataRoot = this.dataRoot || "";
	
//	var refSeqs = params.refSeqs;
//	var trackData = params.trackData;
//	this.deferredFunctions = [];
//	this.dataRoot = params.dataRoot;
//	var dataRoot;
//	if ("dataRoot" in params)
//		dataRoot = params.dataRoot;
//	else
//		dataRoot = "";

	//console.log("js.Browser.startup    dataRoot: " + dataRoot);

	this.names = new LazyTrie(dataRoot + "data/names/lazy-",
//	this.names = new LazyTrie(dataRoot + "/names/lazy-",
				  dataRoot + "data/names/root.json");
	////console.log("js.Browser.startup    names:");
	////console.dir({names:names});

	
	this.tracks = [];
	var brwsr = this;
	brwsr.isInitialized = false;

//	dojo.addOnLoad(
//		function() {

		//set up top nav/overview pane and main GenomeView pane
//			dojo.addClass(document.body, "tundra");
//			brwsr.container = dojo.byId(params.containerID);

	brwsr.container = this.mainTab;
	brwsr.container.genomeBrowser = brwsr;

//			var topPane = document.createElement("div");
//			brwsr.container.appendChild(topPane);

//			var overview = document.createElement("div");
//			overview.className = "overview";
//			overview.id = "overview";
//			topPane.appendChild(overview);

	//try to come up with a good estimate of how big the location box
	//actually has to be
	var maxBase = refSeqs.reduce(function(a,b) {return a.end > b.end ? a : b;}).end;
//			var navbox = brwsr.createNavBox(topPane, (2 * (String(maxBase).length + (((String(maxBase).length / 3) | 0) / 2))) + 2, params);
	var navbox = this.createNavBox(this.topPane, (2 * (String(maxBase).length + (((String(maxBase).length / 3) | 0) / 2))) + 2, this.params);



//			var viewElem = document.createElement("div");
//			brwsr.container.appendChild(viewElem);
//			viewElem.className = "dragWindow";

//			var containerWidget = new dijit.layout.BorderContainer({
//				liveSplitters: false,
//				design: "sidebar",
//				gutters: false
//			}, brwsr.container);
//			var contentWidget = new dijit.layout.ContentPane({region: "top"}, topPane);
//			var browserWidget = new dijit.layout.ContentPane({region: "center"}, viewElem);

	// GET contentWidget AND browserWidget
	var contentWidget = this.topPane;
	var browserWidget = this.centerPane;


// LATER: CONVERT THIS TO MARKUP
	//create location trapezoid
	brwsr.locationTrap = document.createElement("div");
	brwsr.locationTrap.className = "locationTrap";

	this.topPane.domNode.appendChild(brwsr.locationTrap);
	//			topPane.appendChild(brwsr.locationTrap);
	//			topPane.style.overflow="hidden";

	//set up ref seqs
	brwsr.allRefs = {};
	for (var i = 0; i < refSeqs.length; i++)
		brwsr.allRefs[refSeqs[i].name] = refSeqs[i];



//			var refCookie = dojo.cookie(params.containerID + "-refseq");
	//var refCookie = dojo.cookie(this.params.containerID + "-refseq");

	brwsr.refSeq = refSeqs[0];
	//console.log("js.Browser.startup    this.locationObject: " + dojo.toJson(this.locationObject));
	
	for (var i = 0; i < refSeqs.length; i++) {

		brwsr.chromList.options[i] = new Option(refSeqs[i].name,
												refSeqs[i].name);
		if (refSeqs[i].name.toUpperCase() == this.locationObject.name.toUpperCase() ) {
			//console.log("js.Browser.startup    MATCHED REFSEQ: " + brwsr.allRefs[refSeqs[i].name]);
			brwsr.refSeq = brwsr.allRefs[refSeqs[i].name];
			brwsr.chromList.selectedIndex = i;
		}

		//if (refSeqs[i].name.toUpperCase() == String(refCookie).toUpperCase()) {
		//	brwsr.refSeq = brwsr.allRefs[refSeqs[i].name];
		//	brwsr.chromList.selectedIndex = i;
		//}
	}

	dojo.connect(brwsr.chromList, "onchange", function(event) {

		//var oldLocMap = dojo.fromJson(dojo.cookie(brwsr.container.id + "-location")) || {};

		//console.log("js.Browser.startup    chromoList.onchange fired    dojo.cookie(brwsr.container.id + '-location'): " + dojo.cookie(brwsr.container.id + "-location"));

		var newRef = brwsr.allRefs[brwsr.chromList.options[brwsr.chromList.selectedIndex].value];

		//if (oldLocMap[newRef.name])
		//	brwsr.navigateTo(newRef.name + ":"
		//					 + oldLocMap[newRef.name]);
		//else

			brwsr.navigateTo(newRef.name + ":"
							 + (((newRef.start + newRef.end) * 0.4) | 0)
							 + " .. "
							 + (((newRef.start + newRef.end) * 0.6) | 0));
	});

	//hook up GenomeView
//			var gv = new GenomeView(viewElem, 250, brwsr.refSeq, 1/200);
	var gv = new GenomeView(this.viewElem.containerNode, 250, brwsr.refSeq, 1/200, this);
	brwsr.view = gv;
//			brwsr.viewElem = viewElem;
	brwsr.viewElem = this.viewElem;
	//gv.setY(0);
//			viewElem.view = gv;
	this.viewElem.view = gv;

	dojo.connect(browserWidget, "resize", function() {
			gv.sizeInit();

			brwsr.view.locationTrapHeight = dojo.marginBox(navbox).h;
			gv.showVisibleBlocks();
			gv.showFine();
			gv.showCoarse();
		});
	brwsr.view.locationTrapHeight = dojo.marginBox(navbox).h;

	dojo.connect(gv, "onFineMove", brwsr, "onFineMove");
	dojo.connect(gv, "onCoarseMove", brwsr, "onCoarseMove");

	//set up track list
//			var trackListDiv = brwsr.createTrackList(brwsr.container, params);
//	var trackListDiv = brwsr.createTrackList(brwsr.container, this.params);
//			containerWidget.startup();

	//console.log("js.Browser.startup    Doing trackListDiv = brwsr.createTrackList(brwsr.container, this.params)");


	//console.log("js.Browser.startup    this.params: ");
	//console.dir({params:this.params});
	var trackListDiv = brwsr.createTrackList(brwsr.container, this.params);

	brwsr.isInitialized = true;

	// set initial location
	var oldLocMap = dojo.fromJson(dojo.cookie(brwsr.container.id + "-location")) || {};
	//console.log("js.Browser.startup    BEFORE CALL TO this.navigateTo");
	//console.log("js.Browser.startup    this.params.location: " + this.params.location);
//			if (params.location) {
//				brwsr.navigateTo(params.location);
	if (this.params.location) {
		brwsr.navigateTo(this.params.location);
	} else if (oldLocMap[brwsr.refSeq.name]) {
		brwsr.navigateTo(brwsr.refSeq.name
						 + ":"
						 + oldLocMap[brwsr.refSeq.name]);
//			} else if (params.defaultLocation){
//				brwsr.navigateTo(params.defaultLocation);
	} else if (this.params.defaultLocation){
		brwsr.navigateTo(this.params.defaultLocation);
	} else {
		brwsr.navigateTo(brwsr.refSeq.name
						 + ":"
						 + ((((brwsr.refSeq.start + brwsr.refSeq.end)
							  * 0.4) | 0)
							+ " .. "
							+ (((brwsr.refSeq.start + brwsr.refSeq.end)
								* 0.6) | 0)));
	}

	//if someone calls methods on this browser object
	//before it's fully initialized, then we defer
	//those functions until now
	for (var i = 0; i < brwsr.deferredFunctions.length; i++)
	brwsr.deferredFunctions[i]();
	brwsr.deferredFunctions = [];
//		});
//};
},
/**
 * @private
 */
//onFineMove = function(startbp, endbp) {
onFineMove : function(startbp, endbp) {
	var length = this.view.ref.end - this.view.ref.start;
	var trapLeft = Math.round((((startbp - this.view.ref.start) / length)
							   * this.view.overviewBox.w) + this.view.overviewBox.l);
	var trapRight = Math.round((((endbp - this.view.ref.start) / length)
								* this.view.overviewBox.w) + this.view.overviewBox.l);
	var locationTrapStyle;
	if (dojo.isIE) {
		//IE apparently doesn't like borders thicker than 1024px
		locationTrapStyle =
			"top: " + this.view.overviewBox.t + "px;"
			+ "height: " + this.view.overviewBox.h + "px;"
			+ "left: " + trapLeft + "px;"
			+ "width: " + (trapRight - trapLeft) + "px;"
			+ "border-width: 0px";
	} else {
		locationTrapStyle =
			"top: " + this.view.overviewBox.t + "px;"
			+ "height: " + this.view.overviewBox.h + "px;"
			+ "left: " + this.view.overviewBox.l + "px;"
			+ "width: " + (trapRight - trapLeft) + "px;"
			+ "border-width: " + "0px "
			+ (this.view.overviewBox.w - trapRight) + "px "
			+ this.view.locationTrapHeight + "px " + trapLeft + "px;";
	}

	this.locationTrap.style.cssText = locationTrapStyle;
//};
},
/**
 * @private
 */
//createTrackList = function(parent, params) {
createTrackList : function(parent, params) {
	//console.log("js.Browser.createTrackList    js.Browser.createTrackList    (parent, params)");
	//console.log("js.Browser.createTrackList    params: ");
	//console.dir({params:params});

	// ADDED: HOOK TO CONTAINER NODE IN TEMPLATE
//	var leftPane = document.createElement("div");
//	leftPane.style.cssText="width: 10em";
//	parent.appendChild(leftPane);
	var leftPane = this.leftPane.containerNode;

	// ADDED: HOOK TO LEFT PANE IN TEMPLATE
//	var leftWidget = new dijit.layout.ContentPane({region: "left", splitter: true}, leftPane);
	var leftWidget = this.leftPane;
	var trackListDiv = document.createElement("div");
	//trackListDiv.id = "tracksAvail";
	trackListDiv.className = "container handles";
	trackListDiv.style.cssText =
		"width: 100%; height: 100%; overflow-x: hidden; overflow-y: auto; text-align: center";
	trackListDiv.innerHTML = ""
		//"(Drag Tracks<img src=\""
		//+ (params.browserRoot ? params.browserRoot : "")
		//+ "img/right_arrow.png\"/> To View)<br/>";	
	leftPane.appendChild(trackListDiv);

	var brwsr = this;

	var changeCallback = function() {
		brwsr.view.showVisibleBlocks(true);
	};

	var setNodeDblClick = function (node, url) {
		console.log("js.Browser.trackListCreate    setNodeDblClick     url: "  + url);

		node.ondblclick = function(event) {
			console.log("js.Browser.trackListCreate    DOING node.DOUBLECLICK url: "  + url);
			window.open(url, "_blank");
			event.stopPropagation();
		};
	};


	var trackListCreate = function(track, hint) {

//console.log("js.Browser.createTrackList    trackListCreate track:");
//console.dir({track:track});

		var node = document.createElement("div");
		node.className = "tracklist-label";
		node.innerHTML = track.key;

		// ADDED: ONCLICK IF trackInfo.infoUrl EXISTS
		for ( var i = 0; i < params.trackData.length; i++ ) {
			if ( params.trackData[i].label == track.label ) {
				if ( params.trackData[i].urlInfo ) {
					setNodeDblClick(node, params.trackData[i].urlInfo);
				}
				break;
			}		
		}
		
		// ADDED: source LABEL CLASS
		for ( var i = 0; i < params.trackData.length; i++ ) {
			
			if ( params.trackData[i].label == track.label ) {
				dojo.addClass(node, params.trackData[i].label + "-label");
				if ( params.trackData[i].sourceType != null ) {
					dojo.addClass(node, params.trackData[i].sourceType + "-label");
				}
				continue;
			}	
		}

		//in the list, wrap the list item in a container for
		//border drag-insertion-point monkeying
		if ("avatar" != hint) {
			var container = document.createElement("div");
			container.className = "tracklist-container";
			container.appendChild(node);
			node = container;
		}
//		// SET FANCY FORMAT IN NODE INNERHTML
//		else {
//			var avatarHtml = "<table><tr>"; 
//			avatarHtml += "<td class='dojoDndAvatarHeader'><strong style='color: darkred'>" + track.label + "</strong></td>";
//			//if ( track.sourceType )
//			//	avatarHtml += "<td class=\"" + track.sourceType + "-label\"></td>";
//			avatarHtml += "</tr></table>";
//			node.innerHTML = avatarHtml;
//			dojo.addClass(node, track.label + "-label");
//			if ( track.sourceType )
//				dojo.addClass(node, track.sourceType + "-label");
//			
//		}
		node.id = dojo.dnd.getUniqueId();
		return {node: node, data: track, type: ["track"]};
	};

	this.listTracks = function () {
		var allNodes = brwsr.viewDndWidget.getAllNodes();
		//console.dir({allNodes:allNodes});
		var array = [];
		for ( var i = 0; i < allNodes.length; i++ ) {
			array.push(allNodes[i].track.name);
		}
		var tracklist = array.join(',');
		return tracklist;
	};

	this.trackListWidget = new dojo.dnd.Source(trackListDiv,
		{
			creator: trackListCreate,
			accept: ["track"],
			withHandles: false
		}
	);

	var trackCreate = function(track, hint) {
		var node;
		if ("avatar" == hint) {
			return trackListCreate(track, hint);
		} else {
			var replaceData = {refseq: brwsr.refSeq.name};
			var url = track.url.replace(/\{([^}]+)\}/g, function(match, group) {return replaceData[group];});
			var klass = eval(track.type);
			
			// NB: trackBaseUrl IS BROWSER dataRoot
			var trackBaseUrl = brwsr.dataRoot;

			var newTrack = new klass(track, url, brwsr.refSeq,
			{
				changeCallback: changeCallback,
				trackPadding: brwsr.view.trackPadding,

				parentWidget: brwsr.parentWidget,

				//ADDED: CHANGED baseUrl TO trackBaseUrl
				//baseUrl: brwsr.dataRoot,
				baseUrl: trackBaseUrl,

				charWidth: brwsr.view.charWidth,
				seqHeight: brwsr.view.seqHeight
			});
			node = brwsr.view.addTrack(newTrack);


			// ADDED: ADD NEW TRACK IN CORRECT ORDER TO TRACKLIST IN View.js
			setTimeout(
				function ()
				{
					brwsr.viewObject.tracklist = brwsr.listTracks();
					brwsr.parentWidget.updateViewTracklist(brwsr.viewObject);
				},
				100
			);
		}
		return {node: node, data: track, type: ["track"]};
	};

	this.viewDndWidget = new dojo.dnd.Source(this.view.zoomContainer,
		{
			creator: trackCreate,
			accept: ["track"],
			withHandles: true
		});
	
	
	dojo.subscribe("/dnd/drop", function(source,nodes,iscopy){

//console.log("js.Browser.createTrackList    inside dojo.subscribe('/dnd/drop')    source:");
//console.dir({source:source});

		brwsr.onVisibleTracksChanged();
		//multi-select too confusing?
		//brwsr.viewDndWidget.selectNone();

		// ADDED: SIGNAL REMOVE TRACK IN View.js
		// NB: USE track.name FOR NAME OF TRACK
		if ( source === brwsr.viewDndWidget )
		{
			//console.log("js.Browser.createTrackList    /dnd/drop   nodes[0].track.name: " + nodes[0].track.name);
			//console.dir({track:nodes[0].track});
			//console.dir({trackListWidget:brwsr.trackListWidget});
			//console.dir({viewDndWidget:brwsr.viewDndWidget});

			// ADD/REMOVE UPDATE TRACKLIST IN View.js
			if ( source.anchor == null ) {
				brwsr.parentWidget.handleTrackChange(brwsr.viewObject, nodes[0].track.name, "remove");
			}
			else {
				//console.log("js.Browser.createTrackList    MOVED TRACK. UPDATE TRACK ORDERING");
				brwsr.viewObject.tracklist = brwsr.listTracks();
				brwsr.parentWidget.updateViewTracklist(brwsr.viewObject);
			}
		}
	});


	this.trackListWidget.insertNodes(false, params.trackData);

	/*CHANGED */
	var oldTrackList = this.trackList;
	// GET TRACK LIST FROM USER-INPUT ARGS OR USE
	// DEFAULT TRACK LIST FROM LAST TIME USED
//	var oldTrackList = dojo.cookie(this.container.id + "-tracks");
	//if ( oldTrackList == null || ! oldTrackList )
	//{
	//	oldTrackList = dojo.cookie(this.container.id + "-tracks");
	//}


	if (params.tracks) {
		this.showTracks(params.tracks);
	} else if (oldTrackList) {
		this.showTracks(oldTrackList);
	} else if (params.defaultTracks) {
		this.showTracks(params.defaultTracks);
	}

	return trackListDiv;
//};
},
/**
 * @private
 */
//onVisibleTracksChanged = function() {
onVisibleTracksChanged : function() {


	this.view.updateTrackList();


	var trackLabels = dojo.map(this.view.tracks,
							   function(track) { return track.name; });
	
	/*CHANGED */
	//dojo.cookie(this.container.id + "-tracks",
	//			trackLabels.join(","),
	//			{expires: 60});


	this.view.showVisibleBlocks();
//};
},
/**
 * @private
 * add new tracks to the track list
 * @param trackList list of track information items
 * @param replace true if this list of tracks should replace any existing
 * tracks, false to merge with the existing list of tracks
 */
//addTracks = function(trackList, replace) {
addTracks : function(trackList, replace) {

//console.log("Browser.addTracks(trackList, replace)");
//console.log("Browser.addTracks    trackList: " + dojo.toJson(trackList));
//console.log("Browser.addTracks    replace: " + replace);

	if (!this.isInitialized) {
		var brwsr = this;
		this.deferredFunctions.push(
			function() {brwsr.addTracks(trackList, show); }
		);
	return;
	}

	this.tracks.concat(trackList);
	if (show || (show === undefined)) {
		this.showTracks(dojo.map(trackList,
								 function(t) {return t.label;}).join(","));
	}
//};
},
/**
 * navigate to a given location
 * @example
 * gb=dojo.byId("GenomeBrowser").genomeBrowser
 * gb.navigateTo("ctgA:100..200")
 * gb.navigateTo("f14")
 * @param loc can be either:<br>
 * &lt;chromosome&gt;:&lt;start&gt; .. &lt;end&gt;<br>
 * &lt;start&gt; .. &lt;end&gt;<br>
 * &lt;center base&gt;<br>
 * &lt;feature name/ID&gt;
 */
//navigateTo = function(loc) {
navigateTo : function(loc) {
	//console.log("js.Browser.navigateTo    js.Browser.navigateTo(loc)");
	//console.log("js.Browser.navigateTo    caller: " + this.navigateTo.caller.nom);
	//console.log("js.Browser.navigateTo    this.isInitialized: " + this.isInitialized);

	if (!this.isInitialized) {
		//console.log("js.Browser.navigateTo    NOT this.isInitialized");
		var brwsr = this;
		this.deferredFunctions.push(function() { brwsr.navigateTo(loc); });
	return;
	}

	//console.log("js.Browser.navigateTo    loc: " + loc);
	loc = dojo.trim(loc);

	//								(chromosome)	(	start	  )   (  sep	 )	 (	end   )

	// MOVED TO NAVBOX 'Save Location' BUTTON
	//////// ADDED: CONNECT TO browser.navigateTo TO DO this.updateViewLocation
	//////this.parentWidget.updateViewLocation(this.viewObject, loc, this.chromList.value);

	var matches = String(loc).match(/^(((\S*)\s*:)?\s*(-?[0-9,.]*[0-9])\s*(\.\.|-|\s+))?\s*(-?[0-9,.]+)$/i);
	//matches potentially contains location components:
	//matches[3] = chromosome (optional)
	//matches[4] = start base (optional)
	//matches[6] = end base (or center base, if it's the only one)
	if (matches) {
	if (matches[3]) {
		var refName;
		for (ref in this.allRefs) {
		if ((matches[3].toUpperCase() == ref.toUpperCase())
					||
					("CHR" + matches[3].toUpperCase() == ref.toUpperCase())
					||
					(matches[3].toUpperCase() == "CHR" + ref.toUpperCase())) {

			refName = ref;
				}
			}
		if (refName) {


		//console.log("js.Browser.navigateTo    adding cookie: " + this.container.id + "-refseq"+ refName);
		//dojo.cookie(this.container.id + "-refseq", refName, {expires: 60});


		if (refName == this.refSeq.name) {
			//go to given start, end on current refSeq
			this.view.setLocation(this.refSeq,
					  parseInt(matches[4].replace(/[,.]/g, "")),
					  parseInt(matches[6].replace(/[,.]/g, "")));
		} else {
			//new refseq, record open tracks and re-open on new refseq
					var curTracks = [];
					this.viewDndWidget.forInItems(function(obj, id, map) {
							curTracks.push(obj.data);
						});

			for (var i = 0; i < this.chromList.options.length; i++)
			if (this.chromList.options[i].text == refName)
				this.chromList.selectedIndex = i;
			this.refSeq = this.allRefs[refName];
			//go to given refseq, start, end
			this.view.setLocation(this.refSeq,
					  parseInt(matches[4].replace(/[,.]/g, "")),
					  parseInt(matches[6].replace(/[,.]/g, "")));

					this.viewDndWidget.insertNodes(false, curTracks);
					this.onVisibleTracksChanged();
		}
		return;
		}
	} else if (matches[4]) {
		//go to start, end on this refseq
		this.view.setLocation(this.refSeq,
				  parseInt(matches[4].replace(/[,.]/g, "")),
				  parseInt(matches[6].replace(/[,.]/g, "")));
		return;
	} else if (matches[6]) {
		//center at given base
		this.view.centerAtBase(parseInt(matches[6].replace(/[,.]/g, "")));
		return;
	}
	}
	//if we get here, we didn't match any expected location format

	var brwsr = this;
	this.names.exactMatch(loc, function(nameMatches) {
		var goingTo;
		//first check for exact case match
		for (var i = 0; i < nameMatches.length; i++) {
		if (nameMatches[i][1] == loc)
			goingTo = nameMatches[i];
		}
		//if no exact case match, try a case-insentitive match
			if (!goingTo) {
				for (var i = 0; i < nameMatches.length; i++) {
					if (nameMatches[i][1].toLowerCase() == loc.toLowerCase())
						goingTo = nameMatches[i];
				}
			}
			//else just pick a match
		if (!goingTo) goingTo = nameMatches[0];
		var startbp = goingTo[3];
		var endbp = goingTo[4];
		var flank = Math.round((endbp - startbp) * .2);
		//go to location, with some flanking region
		brwsr.navigateTo(goingTo[2]
				 + ":" + (startbp - flank)
				 + ".." + (endbp + flank));
		brwsr.showTracks(brwsr.names.extra[nameMatches[0][0]]);
	});
//};
},
/**
 * load and display the given tracks
 * @example
 * gb=dojo.byId("GenomeBrowser").genomeBrowser
 * gb.showTracks("DNA,gene,mRNA,noncodingRNA")
 * @param trackNameList {String} comma-delimited string containing track names,
 * each of which should correspond to the "label" element of the track
 * information dictionaries
 */
//showTracks = function(trackNameList) {
showTracks : function(trackNameList) {

//console.log("js.Browser.showTracks    trackNameList: " + trackNameList);
	if (!this.isInitialized) {

//console.log("js.Browser.showTracks    PUSHING ONTO this.deferredFunctions: showTracks(trackNameList)");

		var brwsr = this;
		this.deferredFunctions.push(
			function() { brwsr.showTracks(trackNameList); }
		);
	return;
	}

	//console.log("js.Browser.showTracks    Past check for ! this.isInitialized");

	var trackNames = trackNameList.split(",");

	//console.log("js.Browser.showTracks    trackNames: " + dojo.toJson(trackNames));
	//console.log("js.Browser.showTracks    this.trackListWidget: ");
	//console.dir({trackListWidget:this.trackListWidget});

	var removeFromList = [];
	var brwsr = this;
	for (var n = 0; n < trackNames.length; n++) {
		this.trackListWidget.forInItems(function(obj, id, map) {
//console.log("js.Browser.showTracks    trackNames[n]: " + trackNames[n] );
//console.log("js.Browser.showTracks    obj.data.label: " + obj.data.label );
//
			if (trackNames[n] == obj.data.label) {
//console.log("js.Browser.showTracks    Matched. Doing brwsr.viewDndWidget.insertNodes(false, [obj.data])" );

				brwsr.viewDndWidget.insertNodes(false, [obj.data]);
				removeFromList.push(id);
			}
		});
	}

//console.log("js.Browser.showTracks    removeFromList: " + dojo.toJson(removeFromList) );

	var movedNode;
	for (var i = 0; i < removeFromList.length; i++) {
		this.trackListWidget.delItem(removeFromList[i]);

		movedNode = dojo.byId(removeFromList[i]);
		//console.log("js.Browser.showTracks    movedNode = dojo.byId(removeFromList[i]): " + movedNode);

		//// ADDED: TO AVOID ERROR IF movedNode IS NULL
		//if ( movedNode == null )
		//{
		//	setTimeout(function(){
				movedNode = dojo.byId(removeFromList[i]);
				movedNode.parentNode.removeChild(movedNode);
		//	}, 1000);
		//
		//	//this.deferredFunctions.push(
		//	//function() {
		//	//	try {
		//	//		movedNode = dojo.byId(removeFromList[i]);
		//	//		movedNode.parentNode.removeChild(movedNode);
		//	//	}
		//	//	catch(e) {
		//	//		//console.log("js.Browser.showTracks    Could not do deferredFunction movedNode.parentNode.removeChild(movedNode)");
		//	//	}
		//	//});
		//}
		//else
		//{
		//	movedNode = dojo.byId(removeFromList[i]);
		//	movedNode.parentNode.removeChild(movedNode);
		//}
	}
	this.onVisibleTracksChanged();
//};
},
/**
 * @returns {String} string representation of the current location<br>
 * (suitable for passing to navigateTo)
 */
//visibleRegion = function() {
visibleRegion : function() {
	return this.view.ref.name + ":" + Math.round(this.view.minVisible()) + ".." + Math.round(this.view.maxVisible());
//};
},
/**
 * @returns {String} containing comma-separated list of currently-viewed tracks<br>
 * (suitable for passing to showTracks)
 */
//visibleTracks = function() {
visibleTracks : function() {
	var trackLabels = dojo.map(this.view.tracks,
							   function(track) { return track.name; });
	return trackLabels.join(",");
//};
},
/**
 * @private
 */
//onCoarseMove = function(startbp, endbp) {
onCoarseMove : function(startbp, endbp) {
	//console.log("js.Browser.onCoarseMove    js.Browser.onCoarseMove(startbp, endbp)");
	//console.log("js.Browser.onCoarseMove    startbp: " + dojo.toJson(startbp));
	//console.log("js.Browser.onCoarseMove    endbp: " + dojo.toJson(endbp));

	if ( ! startbp || ! endbp ) {
		//console.log("js.Browser.onCoarseMove    ! startbp or ! endbp");
		return;
	}

	//if ( this.onCoarseMove.caller )
	//	//console.log("js.Browser.onCoarseMove    caller: " + this.onCoarseMove.caller.nom);

	//console.log("js.Browser.onCoarseMove    this.isInitialized: " + this.isInitialized);
	if (!this.isInitialized) {
		//console.log("js.Browser.onCoarseMove    NOT this.isInitialized");
		return;
	}

	var length = this.view.ref.end - this.view.ref.start;
	var trapLeft = Math.round((((startbp - this.view.ref.start) / length)
							   * this.view.overviewBox.w) + this.view.overviewBox.l);
	var trapRight = Math.round((((endbp - this.view.ref.start) / length)
								* this.view.overviewBox.w) + this.view.overviewBox.l);

	//console.log("js.Browser.onCoarseMove    here 1");

	this.view.locationThumb.style.cssText =
	"height: " + (this.view.overviewBox.h - 4) + "px; "
	+ "left: " + trapLeft + "px; "
	+ "width: " + (trapRight - trapLeft) + "px;"
	+ "z-index: 20";
	//console.log("js.Browser.onCoarseMove    here 2");

	//since this method gets triggered by the initial GenomeView.sizeInit,
	//we don't want to save whatever location we happen to start at
	if (! this.isInitialized) return;
	var locString = Util.addCommas(Math.round(startbp)) + " .. " + Util.addCommas(Math.round(endbp));
	this.locationBox.value = locString;
	this.goButton.disabled = true;
	this.locationBox.blur();

	//console.log("js.Browser.onCoarseMove    here 3");

	// MOVED: TO NAVBOX 'Save Location' BUTTON
	// ADDED: UPDATE LOCATION IN View.js AND ON SERVER
	//console.log("js.Browser.onCoarseMove    locString: " + dojo.toJson(locString));
	//this.parentWidget.updateViewLocation(this.viewObject, locString, this.chromList.value);
	//console.log("js.Browser.onCoarseMove    here 4");

	
	//var oldLocMap = dojo.fromJson(dojo.cookie(this.container.id + "-location"));

	//if ((typeof oldLocMap) != "object") oldLocMap = {};
	//oldLocMap[this.refSeq.name] = locString;
	//

	//dojo.cookie(this.container.id + "-location",
	//			dojo.toJson(oldLocMap),
	//			{expires: 60});


	document.title = this.refSeq.name + ":" + locString;
//};
},
/**
 * @private
 */
//createNavBox = function(parent, locLength, params) {
createNavBox : function(parent, locLength, params) {
	var brwsr = this;
//	var navbox = document.createElement("div");
	var browserRoot = params.browserRoot ? params.browserRoot : "";
	var navbox = this.navbox;
//	navbox.id = "navbox";
//	parent.appendChild(navbox);
//	navbox.style.cssText = "text-align: center; padding: 2px; z-index: 10;";

	if (params.bookmark) {
		this.link = document.createElement("a");
		this.link.appendChild(document.createTextNode("Link"));
		this.link.href = window.location.href;
		dojo.connect(this, "onCoarseMove", function() {
						 brwsr.link.href = params.bookmark(brwsr);
					 });
		dojo.connect(this, "onVisibleTracksChanged", function() {
						 brwsr.link.href = params.bookmark(brwsr);
					 });
		this.link.style.cssText = "float: right; clear";
		navbox.appendChild(this.link);
	}

		// ADDED: 'Save Location' BUTTON WITH CONNECT TO
	// parentWidget.updateViewLocation
	this.saveButton = document.createElement("button");
	this.saveButton.appendChild(document.createTextNode("Save Location"));
	dojo.addClass(this.saveButton, "saveButton");

	dojo.connect(this.saveButton, "click", function(event) {
		//console.log("Browser.createNavBox    Save Location Button click    brwsr.locationBox.value: " + brwsr.locationBox.value);
		brwsr.parentWidget.updateViewLocation(brwsr.viewObject, brwsr.locationBox.value, brwsr.chromList.value);
		dojo.stopEvent(event);
	});
	navbox.appendChild(this.saveButton);
	
	
	var moveLeft = document.createElement("input");
	moveLeft.type = "image";
	moveLeft.src = browserRoot + "img/slide-left.png";
	//console.log("js.Browser.createNavBox    browserRoot: "  + browserRoot);
	//console.log("js.Browser.createNavBox    moveLeft.src: "  + moveLeft.src);
	moveLeft.id = "moveLeft";
	moveLeft.className = "icon nav";
	moveLeft.style.height = "40px";
	dojo.connect(moveLeft, "click",
				 function(event) {
					 dojo.stopEvent(event);
					 brwsr.view.slide(0.9);
				 });
	navbox.appendChild(moveLeft);

	var moveRight = document.createElement("input");
	moveRight.type = "image";
	moveRight.src = browserRoot + "img/slide-right.png";
	moveRight.id="moveRight";
	moveRight.className = "icon nav";
	moveRight.style.height = "40px";
	dojo.connect(moveRight, "click",
				 function(event) {
					 dojo.stopEvent(event);
					 brwsr.view.slide(-0.9);
				 });
	navbox.appendChild(moveRight);

	navbox.appendChild(document.createTextNode("\u00a0\u00a0\u00a0\u00a0"));

	var bigZoomOut = document.createElement("input");
	bigZoomOut.type = "image";
	bigZoomOut.src = browserRoot + "img/zoom-out-2.png";
	bigZoomOut.id = "bigZoomOut";
	bigZoomOut.className = "icon nav";
	bigZoomOut.style.height = "40px";
	navbox.appendChild(bigZoomOut);
	dojo.connect(bigZoomOut, "click",
				 function(event) {
					 dojo.stopEvent(event);
					 brwsr.view.zoomOut(undefined, undefined, 2);
				 });

	var zoomOut = document.createElement("input");
	zoomOut.type = "image";
	zoomOut.src = browserRoot + "img/zoom-out-1.png";
	zoomOut.id = "zoomOut";
	zoomOut.className = "icon nav";
	zoomOut.style.height = "40px";
	dojo.connect(zoomOut, "click",
				 function(event) {
					 dojo.stopEvent(event);
					 brwsr.view.zoomOut();
				 });
	navbox.appendChild(zoomOut);

	var zoomIn = document.createElement("input");
	zoomIn.type = "image";
	zoomIn.src = browserRoot + "img/zoom-in-1.png";
	zoomIn.id = "zoomIn";
	zoomIn.className = "icon nav";
	zoomIn.style.height = "40px";
	dojo.connect(zoomIn, "click",
				 function(event) {
					 dojo.stopEvent(event);
					 brwsr.view.zoomIn();
				 });
	navbox.appendChild(zoomIn);

	var bigZoomIn = document.createElement("input");
	bigZoomIn.type = "image";
	bigZoomIn.src = browserRoot + "img/zoom-in-2.png";
	bigZoomIn.id = "bigZoomIn";
	bigZoomIn.className = "icon nav";
	bigZoomIn.style.height = "40px";
	dojo.connect(bigZoomIn, "click",
				 function(event) {
					 dojo.stopEvent(event);
					 brwsr.view.zoomIn(undefined, undefined, 2);
				 });
	navbox.appendChild(bigZoomIn);

	navbox.appendChild(document.createTextNode("\u00a0\u00a0\u00a0\u00a0"));

	this.chromList = document.createElement("select");
	this.chromList.id="chrom";
	
	// ADDED: CHROMLIST CSS CLASS
	dojo.addClass(this.chromList, "chromList");

	
	navbox.appendChild(this.chromList);
	this.locationBox = document.createElement("input");
	this.locationBox.size=locLength;
	this.locationBox.type="text";
	this.locationBox.id="location";
	dojo.connect(this.locationBox, "keydown", function(event) {
			if (event.keyCode == dojo.keys.ENTER) {
				brwsr.navigateTo(brwsr.locationBox.value);
				//brwsr.locationBox.blur();
				brwsr.goButton.disabled = true;
				dojo.stopEvent(event);
			} else {
				brwsr.goButton.disabled = false;
			}
		});
	navbox.appendChild(this.locationBox);

	this.goButton = document.createElement("button");
	this.goButton.appendChild(document.createTextNode("Go"));
	this.goButton.disabled = true;
	dojo.connect(this.goButton, "click", function(event) {
			brwsr.navigateTo(brwsr.locationBox.value);
			//brwsr.locationBox.blur();
			brwsr.goButton.disabled = true;
			dojo.stopEvent(event);
		});
	navbox.appendChild(this.goButton);

	// ADDED: 'Go' BUTTON CLASS
	dojo.addClass(this.goButton, "goButton");

	
	return navbox;
	}
});

/*

Copyright (c) 2007-2009 The Evolutionary Software Foundation

Created by Mitchell Skinner <mitch_skinner@berkeley.edu>

This package and its accompanying libraries are free software; you can
redistribute it and/or modify it under the terms of the LGPL (either
version 2.1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text.

*/
