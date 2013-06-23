define([
	"dojo/_base/declare",
	"dojo/_base/array",
	"dojo/json",
	"dojo/on",
	"dojo/_base/lang",
	"dojo/dom-attr",
	"dojo/dom-class",
	"dojo/dom-construct",
	"plugins/core/Common",
	"dojox/io/windowName",
	"dojo/ready",
	"dojo/domReady!",

	"plugins/graph/nvd3/lib/d3",
	"plugins/graph/nvd3/nv",
	"plugins/graph/nvd3/src/utils",
	"plugins/graph/nvd3/src/tooltip",
	"plugins/graph/nvd3/src/models/legend",
	"plugins/graph/nvd3/src/models/axis",
	"plugins/graph/nvd3/src/models/scatter",
	"plugins/graph/nvd3/src/models/line",
	"plugins/graph/nvd3/src/models/historicalBar",
	"plugins/graph/nvd3/src/models/linePlusBarWithFocusChart"
],

function (declare, arrayUtil, JSON, on, lang, domAttr, domClass, domConstruct, Common, windowName, D3, NV3, ready) {

////}}}}}

return declare("plugins.graph.Graph",[Common], {

// cssFiles : Array
// CSS FILES
cssFiles : [
	require.toUrl("dojo/resources/dojo.css"),
	require.toUrl("plugins/graph/css/graph.css"),
	require.toUrl("dojox/layout/resources/ExpandoPane.css"),
	require.toUrl("plugins/graph/nvd3/src/nv.d3.css")
],

// callback : Function reference
// Call this after module has loaded
callback : null,

//////}}
constructor : function(args) {		
	
    // MIXIN ARGS
    lang.mixin(this, args);

	// LOAD CSS
	this.loadCSS();
},
print : function (target, data, graphType, xLabel, yLabel, legend) {
	console.log("Graph.print    graphType: " + graphType);
	console.log("Graph.print    target: " + target);
	console.dir({target:target});

	// CREATE CHART NODE
	var div = domConstruct.create("div", null, target);
	console.log("Graph.print    div: " + div);
	console.dir({div:div});
	
	var svg = d3.select(target).append("svg");
	console.log("Graph.print    svg: " + svg);
	console.dir({svg:svg});
	
	this[graphType](target, svg[0][0], data, xLabel, yLabel, legend);
},
lineChart : function (target, svg, data, xLabel, yLabel, legend) {
	console.log("Graph.lineChart    target: " + target);
	console.dir({target:target});
	console.log("Graph.lineChart    data: " + data);
	console.dir({data:data});
	console.log("Graph.lineChart    svg: " + svg);
	console.dir({svg:svg});
	console.log("Graph.lineChart    d3: " + d3);
	console.dir({d3:d3});
	
	var chart = nv.models.lineChart();

	console.log("Graph.lineChart    BEFORE");

	chart.xAxis
		.axisLabel('Time (ms)')
		.tickFormat(d3.format(',r'));
	
	console.log("Graph.lineChart    BEFORE chart.yAxis");
	chart.yAxis
		.axisLabel('Blood Glucose (ppm)')
		.tickFormat(d3.format('.02f'));
	
	console.log("Graph.lineChart    BEFORE d3.select");
	d3.select(svg)
		.datum(data)
		.transition().duration(500)
		.call(chart);
	
	console.log("Graph.lineChart    AFTER");
	
	nv.utils.windowResize(chart.update);

  return chart;
	
},
linePlusBarWithFocusChart : function (target, svg, data, xLabel, yLabel, legend) {
	console.log("Graph.linePlusBarWithFocusChart    svg:")
	console.dir({svg:svg});
	
	nv.addGraph(function() {
    var chart = nv.models.linePlusBarWithFocusChart()
        .margin({top: 30, right: 60, bottom: 50, left: 70})
        .x(function(d,i) { return i })
        .color(d3.scale.category10().range());

	chart.xAxis.tickFormat(function(d) {
		var dx = data[0].values[d] && data[0].values[d].x || 0;
		if (dx > 0) {
			return d3.time.format('%x')(new Date(dx))
		}
		return null;
    });

    chart.x2Axis.tickFormat(function(d) {
		var dx = data[0].values[d] && data[0].values[d].x || 0;
		return d3.time.format('%x')(new Date(dx))
    });

	// GET HEIGHT AND WIDTH    
	var height = svg.offsetHeight;
	var width = svg.offsetWidth;
	console.log("Graph.linePlusBarWithFocusChart    height: " + height)
	console.log("Graph.linePlusBarWithFocusChart    width: " + width)

	// X-AXIS LABEL
	//d3.select('#chart1 svg')
	d3.select(svg)
		.append("text")      // text label for the x axis
        .attr("x", 120)
        .attr("y", 770)
        .style("text-anchor", "middle")
        .style("font-weight", "bold")
        .style("font-size", "20px")
        .text(xLabel);

//	.attr("x", width / 2 )
//        .attr("y",  height + margin.bottom)	
		
	// Y-AXIS LABEL
	//d3.select('#chart1 svg')
	d3.select(svg)
		.append("text")      // text label for the x axis
        .attr("x", 25)
        .attr("y", 690)
        .style("text-anchor", "middle")
        .style("font-weight", "bold")
        .style("font-size", "20px")
        .text("Freq");
		
    console.log("Graph.linePlusBarWithFocusChart    HERE 3")
    chart.y1Axis
        .tickFormat(d3.format(',f'));

    //console.log("Graph.linePlusBarWithFocusChart    HERE 4")
    //chart.y3Axis
    //    .tickFormat(d3.format(',f'));
    
    //console.log("Graph.linePlusBarWithFocusChart    HERE 5")
    //chart.y2Axis
    //    .tickFormat(function(d) { return  d3.format(',.2f')(d) });
    //
    //console.log("Graph.linePlusBarWithFocusChart    HERE 6")
    //chart.y4Axis
    //    .tickFormat(function(d) { return d3.format(',.2f')(d) });

    //console.log("Graph.linePlusBarWithFocusChart    HERE 7")
    //chart.lines.forceY([0]);
    ////chart.bars.forceY([0]);
    //
    //console.log("Graph.linePlusBarWithFocusChart    HERE 8")
    //chart.bars2.forceY([0]);
    ////chart.lines2.forceY([0]);

    console.log("Graph.linePlusBarWithFocusChart    HERE 9")
    console.log("Graph.linePlusBarWithFocusChart    chart:")
	console.dir({chart:chart});
    //d3.select('#chart1 svg')
    //    .datum(data)
    //  .transition().duration(500).call(chart);

//	var selected =
//		d3.select('#chart1 svg')
//        .datum(data)
//		.transition()
//		.duration(500);
//    console.log("Graph.linePlusBarWithFocusChart    selected:")
//	console.dir({selected:selected});
		

    //d3.select('#chart1 svg')
    d3.select(svg)
        .datum(data)
		.transition()
		.duration(500)
		.call(chart);

    console.log("Graph.linePlusBarWithFocusChart    HERE 10")
    nv.utils.windowResize(chart.update);
	
    return chart;
});

},
dataToSeries : function (data) {
	return data.map(function(series) {
		series.values = series.values.map(function(d) { return {x: parseInt(d[0]), y: parseInt(d[1]) } });
		return series;
	});
},
dateToUnixTime : function (year, month, day, hours, minutes, seconds, milliseconds) {
// NOTE: month IS ZERO-INDEXED!! I.E., 00 IS JANUARY, 01 IS FEBRUARY, ...
	if ( ! year ) {
		console.log("Graph.dateToUnixTime    year not defined. Returning");
		return;
	}
	
	month 			=	month 			|| "";
	day 			=	day 			|| "";
	hours 			=	hours 			|| "";
	minutes 		=	minutes 		|| "";
	seconds 		=	seconds 		|| "";
	milliseconds	=	milliseconds 	|| "";
		
	var d = new Date(year, month, day, hours, minutes, seconds, milliseconds);
	var unixTime = d.getTime() / 1000;
	//console.log("Graph.dateToUnixTime    unixTime: " + unixTime);
	
	return unixTime;
},
parseUSDate : function (date) {
	var array 	= date.split("-");

	return [ array[0], array[1] - 1, array[2] ];
},
csvToValues : function (csv, columns) {
	console.log("Graph.csvToValues    csv: ");
	console.dir({csv:csv});
	console.log("Graph.csvToValues    columns: " + columns);

	var column1 = columns[0];	
	var column2 = columns[1];
	var data = [];
	for ( var i = 0; i < csv.length; i++ ) {
		var elements = csv[i].split(",");
		//console.log("Graph.csvToValues    elements: ");
		//console.dir({elements:elements});
		data.push([ elements[column1], elements[column2] ]);
	}

	return data;
},
limitChecked : function () {
/* You then have to call this function in the Mouse Up event of each of the 12 check boxes like this:
 
limitColourOptions();
 
This code assumes that at least one of the Fade radio buttons will be selected. It also doesn't handle the case where two check boxes are selected because Fade was Yes, but the user then selectes a Fade of No, but this could be fixed by resetting all of the check boxes to Off whenever a Fade selection is made. Post again if you need help with this.

*/

    // Get the value of the radio button
    var v = getField("Fade").value;

    // Set the maximum number of check boxes that can be selected (default: Fade = No)
    var max_cbs = v == "Yes" ? 2 : 1;

    // Initialize the selected check box count
    var count = 0;

    // Loop through the check boxes to see if the limit has been exceeded
    for (var i = 0; i < 12; i += 1) {

        // Increment the counter if the current check box is selected
        if (getField("box." + i).value !== "Off") count += 1;

        // If the count exceeds the limit, deselect the check box that was just selected
        // and alert the user
        if (count > max_cbs) {
            event.target.value = "Off";
            app.alert("Only " + max_cbs + " colour(s) available for this option.", 3);
            break;
        }
    }
}



}); 	//	end declare

});	//	end define

