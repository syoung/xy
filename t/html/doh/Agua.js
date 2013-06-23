define(
	[
		"dojo/_base/declare"
		,"plugins/core/Agua/Data"
		,"plugins/core/Agua/Project"
		,"plugins/core/Common/Array"
		,"plugins/core/Common/Sort"
		,"plugins/core/Common/Util"
	],

function(declare, Data, Project, Array, Sort, Util){	
	var Agua = new declare("t.doh.Agua", [Data, Project, Array, Sort, Util], {
	
		cookies : []
	});

	return new Agua({});
}

);
