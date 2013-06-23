define([
	"dojo/_base/declare", // declare
	"dijit/layout/TabContainer",
	"dijit/registry",
	"dojo/topic", // publish
	"dojo/dom-class", // domClass.add domClass.replace
	"dojo/when"
	
], function(declare, TabContainer, registry, topic, domClass, when){

	// module:
	//		dijit/layout/TabContainer

	return declare("plugins.dijit.layout.TabContainer", [TabContainer],
				   {
		// summary:
		//		A Container with tabs to select each child (only one of which is displayed at a time).
		// description:
		//		A TabContainer is a container that has multiple panes, but shows only
		//		one pane at a time.  There are a set of tabs corresponding to each pane,
		//		where each tab has the name (aka title) of the pane, and optionally a close button.
		//
		//		See `StackContainer.ChildWidgetProperties` for details on the properties that can be set on
		//		children of a `TabContainer`.


		//selectChild: function(/*dijit/_WidgetBase|String*/ page, /*Boolean*/ animate){
		//	// summary:
		//	//		Show the given widget (which must be one of my children)
		//	// page:
		//	//		Reference to child widget or id of child widget
		//
		//	console.log("plugins.dijit.layout.StackContainer.selectChild    page: " + page);
		//	console.dir({page:page});
		//	console.log("plugins.dijit.layout.StackContainer.selectChild    animate: " + animate);
		//	console.log("plugins.dijit.layout.StackContainer.selectChild    this.selectedChildWidget: " + this.selectedChildWidget);
		//	console.dir({this_selectedChildWidget:this.selectedChildWidget});
		//	
		//	var d;
		//
		//	page = registry.byId(page);
		//	console.log("plugins.dijit.layout.StackContainer.selectChild    AFTER registry.byId page: " + page);
		//	console.dir({page:page});
		//
		//	if(this.selectedChildWidget != page){
		//
		//		// Deselect old page and select new one
		//		console.log("plugins.dijit.layout.StackContainer.selectChild    DOING d = this._transition(...)");
		//		d = this._transition(page, this.selectedChildWidget, animate);
		//
		//		console.log("plugins.dijit.layout.StackContainer.selectChild    DOING this._set('selectedChildWidget' , page)");
		//		this._set("selectedChildWidget", page);
		//
		//		console.log("plugins.dijit.layout.StackContainer.selectChild    DOING topic.publish(...)");
		//		topic.publish(this.id + "-selectChild", page);	// publish
		//
		//		if(this.persist){
		//			cookie(this.id + "_selectedChild", this.selectedChildWidget.id);
		//		}
		//	}
		//
		//	// d may be null, or a scalar like true.  Return a promise in all cases
		//	return when(d || true);		// Promise
		//},
		//_transition: function(newWidget, oldWidget /*===== ,  animate =====*/){
		//	// summary:
		//	//		Hide the old widget and display the new widget.
		//	//		Subclasses should override this.
		//	// newWidget: dijit/_WidgetBase
		//	//		The newly selected widget.
		//	// oldWidget: dijit/_WidgetBase
		//	//		The previously selected widget.
		//	// animate: Boolean
		//	//		Used by AccordionContainer to turn on/off slide effect.
		//	// tags:
		//	//		protected extension
		//	console.log("plugins.dijit.layout.StackContainer._transition    newWidget: " + newWidget);
		//	console.dir({newWidget:newWidget});
		//	console.log("plugins.dijit.layout.StackContainer._transition    oldWidget: " + oldWidget);
		//	console.dir({oldWidget:oldWidget});
		//	console.log("plugins.dijit.layout.StackContainer._transition    this.doLayout: " + this.doLayout);
		//
		//	if(oldWidget){
		//		this._hideChild(oldWidget);
		//	}
		//	var d = this._showChild(newWidget);
		//
		//	// Size the new widget, in case this is the first time it's being shown,
		//	// or I have been resized since the last time it was shown.
		//	// Note that page must be visible for resizing to work.
		//	if(newWidget.resize){
		//		if(this.doLayout){
		//			console.log("plugins.dijit.layout.StackContainer._transition    DOING newWidget.resize(this._containerContentBox || this._contentBox)");
		//			
		//			
		//			newWidget.resize(this._containerContentBox || this._contentBox);
		//		}else{
		//			console.log("plugins.dijit.layout.StackContainer._transition    DOING newWidget.resize()");
		//			// the child should pick it's own size but we still need to call resize()
		//			// (with no arguments) to let the widget lay itself out
		//			newWidget.resize();
		//		}
		//	}
		//
		//	return d;	// If child has an href, promise that fires when the child's href finishes loading
		//},
		//_showChild: function(/*dijit/_WidgetBase*/ page){
		//	// summary:
		//	//		Show the specified child by changing it's CSS, and call _onShow()/onShow() so
		//	//		it can do any updates it needs regarding loading href's etc.
		//	// returns:
		//	//		Promise that fires when page has finished showing, or true if there's no href
		//
		//	console.log("plugins.dijit.layout.StackContainer._showChild    page: " + page);
		//	console.dir({page:page});
		//
		//	var children = this.getChildren();
		//	page.isFirstChild = (page == children[0]);
		//	page.isLastChild = (page == children[children.length - 1]);
		//	page._set("selected", true);
		//
		//	if ( ! page._wrapper ) {
		//		page._wrapper = page.domNode.parentNode;
		//	}
		//	
		//	domClass.replace(page._wrapper, "dijitVisible", "dijitHidden");
		//
		//	return (page._onShow && page._onShow()) || true;
		//},
		//
		//_hideChild: function(/*dijit/_WidgetBase*/ page){
		//	// summary:
		//	//		Hide the specified child by changing it's CSS, and call _onHide() so
		//	//		it's notified.
		//
		//	console.log("plugins.dijit.layout.StackContainer._hideChild    page: " + page);
		//	console.dir({page:page});
		//
		//	if ( ! page._wrapper ) {
		//		page._wrapper = page.domNode.parentNode;
		//	}
		//
		//	page._set("selected", false);
		//	domClass.replace(page._wrapper, "dijitHidden", "dijitVisible");
		//
		//	page.onHide && page.onHide();
		//}



		
	});
});
