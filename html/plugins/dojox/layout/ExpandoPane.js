dojo.provide("plugins.dojox.layout.ExpandoPane");

dojo.require("dojox.layout.ExpandoPane");

dojo.declare("plugins.dojox.layout.ExpandoPane",
	[ dojox.layout.ExpandoPane ],
{

	// summary: An adaptation of dojox.layout.ExpandoPane to allow the middle
	// 			pane to be shown/hidden, with corresponding adjustments to the
	//			width of the right pane
	//
	width : null,
	minWidth : 15,
	height : null,
	minHeight : 15,
	expand : false,
	
	//postCreate : function ()
	//{
	//	console.log("ExpandoPane.postCreate    plugins.dojox.layout.ExpandoPane.postCreate");
	//
	//	this.inherited(arguments);
	//	
	//	//this.expand = arguments.expand;		
	//	//console.log("ExpandoPane.postCreate    this.expand: " + this.expand);
	//	//console.log("ExpandoPane.postCreate    this.region: " + this.region);
	//
	//},

	resize : function(node, newSize){
		//console.log("ExpandoPane.resize    plugins.dojox.layout.ExpandoPane.resize(node, newSize)");

		if ( newSize )
		{
			//console.log("ExpandoPane.resize    this.region: " + this.region + ", newSize.w: " + newSize.w);
		}

		// summary: we aren't a layout widget, but need to act like one:
		var size = dojo.marginBox(this.domNode);
		var h = size.h - this._titleHeight;
		dojo.style(this.containerNode, "height", h + "px");

		if ( newSize && newSize.w )
		{
			dojo.style(this.domNode, "width", newSize.w + "px");
		}
		
		//this.inherited(arguments);

	},


	_showEnd : function()
	{
		//console.log("ExpandoPane._showEnd    plugins.dojox.layout.ExpandoPane._showEnd");
		//console.log("ExpandoPane._showEnd    this.width: " + this.width);

		// summary: Common animation onEnd code - "unclose"	
		dojo.style(this.cwrapper, { opacity: 0, visibility:"visible" });		
		dojo.fadeIn({ node:this.cwrapper, duration:227 }).play(1);
		dojo.removeClass(this.domNode, "dojoxExpandoClosed");
		
		////console.log("ExpandoPane._showEnd    AFTER dojo.hitch(this._container, 'layout', this.region, this), 15)");

		if (this.region)
		{
			switch (this.region)
			{
				case "left" : case "center" : case "right" :
					
					//console.log("ExpandoPane._showEnd    Setting this.domNode.style.width: " + this.width);
					//console.log("ExpandoPane._showEnd    BEFORE this.domNode.style.width: " + this.domNode.style.width);
					this.domNode.style.width = this.width + "px";
					//console.log("ExpandoPane._showEnd    AFTER this.domNode.style.width: " + this.domNode.style.width);
					break;
				case "top" : case "bottom" :
					this.domNode.style.height = this.height + "px";
					break;
			}
		}

		setTimeout(dojo.hitch(this._container, "layout", this.region, this, "show"), 15);
	},


	_hideEnd : function(){
		//console.log("ExpandoPane._hideEnd    plugins.dojox.layout.ExpandoPane._hideEnd()");
		//console.log("ExpandoPane._hideEnd    this.region: " + this.region);

		if (this.region)
		{
			switch (this.region)
			{
				case "left" : case "center" : case "right" :
					//console.log("ExpandoPane._hideEnd    BEFORE this.domNode.style.width: " + this.domNode.style.width);
					dojo.style(this.domNode, "width", this.minWidth + "px");
					//this.domNode.style.width = this.minWidth + "px";
					//console.log("ExpandoPane._hideEnd    AFTER this.domNode.style.width: " + this.domNode.style.width);
										break;
				case "top" : case "bottom" :
					dojo.style(this.domNode, "width", this.minHeight + "px");
					//this.domNode.style.height = this.minHeight + "px";
					break;
			}
		}

		setTimeout(dojo.hitch(this._container, "layout", this.region, this, "hide" ), 15);
	}

});
