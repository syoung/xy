define([
	"dojo/_base/array", // array.forEach
	"dojo/_base/declare", // declare
	"dojo/dom", // dom.setSelectable
	"dojo/dom-attr", // domAttr.set or get domAttr.remove
	"dojo/dom-class", // domClass.replace
	"dojo/dom-geometry", // domGeometry.setMarginBox domGeometry.getMarginBox
	"dojo/fx", // fxUtils.wipeIn fxUtils.wipeOut
	"dijit/TitlePane",
	"dojo/ready",
	"dojo/domReady!"
], function(array, declare, dom, domAttr, domClass, domGeometry, fxUtils, TitlePane, ready){

return declare("plugins.dijit.TitlePane",[TitlePane], {

//dojo.provide("plugins.dijit.TitlePane");
//
//dojo.require("dijit.TitlePane");
//
//dojo.declare("plugins.dijit.TitlePane",
//	[dijit.TitlePane],
//{
	// summary:
	//		ADAPTED dijit.TitlePane TO ADD EXTRA ELEMENTS TO TEMPLATE
	
	templateString: dojo.cache("plugins", "dijit/templates/TitlePane.html"),

	// NUMBER APPEARS AT FAR RIGHT OF TITLE
	number: null,

	attributeMap: dojo.delegate(dijit.layout.ContentPane.prototype.attributeMap, {
		title: { node: "titleNode", type: "innerHTML" },
		number: { node: "numberNode", type: "innerHTML" },
		tooltip: {node: "focusNode", type: "attribute", attribute: "title"},	// focusNode spans the entire width, titleNode doesn't
		id:""
	}),
	
		postCreate: function(){
			this.inherited(arguments);

			//console.log("pppppppppppppppppppppppppppppppppp plugins.dijit.TitlePane.postCreate");
			
			// Hover and focus effect on title bar, except for non-toggleable TitlePanes
			// This should really be controlled from _setToggleableAttr() but _CssStateMixin
			// doesn't provide a way to disconnect a previous _trackMouseState() call
			if(this.toggleable){
				this._trackMouseState(this.titleBarNode, "dijitTitlePaneTitle");
			}

			// setup open/close animations
			var hideNode = this.hideNode, wipeNode = this.wipeNode;
			this._wipeIn = fxUtils.wipeIn({
				node: wipeNode,
				duration: this.duration,
				beforeBegin: function(){
					hideNode.style.display = "";
				}
			});
			this._wipeOut = fxUtils.wipeOut({
				node: wipeNode,
				duration: this.duration,
				onEnd: function(){
					hideNode.style.display = "none";
				}
			});
		},


	setNumber: function(/*String*/ number){
		// summary:
		//		Deprecated.  Use set('number', ...) instead.
		// tags:
		//		deprecated
		dojo.deprecated("dijit.TitlePane.setNumber() is deprecated.  Use set('number', ...) instead.", "", "2.0");

		this.set("number", number);
	},

	_setContentAttr: function(/*String|DomNode|Nodelist*/ content){
		// summary:
		//		Hook to make set("content", ...) work.
		//		Typically called when an href is loaded.  Our job is to make the animation smooth.

		console.log("plugins.dijit.TitlePane._setContentAttr     SKIPPING");
return;

		if(!this.open || !this._wipeOut || this._wipeOut.status() == "playing"){
			// we are currently *closing* the pane (or the pane is closed), so just let that continue
			this.inherited(arguments);
		}else{
			if(this._wipeIn && this._wipeIn.status() == "playing"){
				this._wipeIn.stop();
			}

	
	return;

			// freeze container at current height so that adding new content doesn't make it jump
			domGeometry.setMarginBox(this.wipeNode, { h: domGeometry.getMarginBox(this.wipeNode).h });

			// add the new content (erasing the old content, if any)
			this.inherited(arguments);

			// call _wipeIn.play() to animate from current height to new height
			if(this._wipeIn){
				this._wipeIn.play();
			}else{
				this.hideNode.style.display = "";
			}
		}
	}

	
	

}); 	//	end declare

});	//	end define
