dojo.provide("t.plugins.xy.module");

try {
    dojo.require("t.plugins.xy.data.test");
    dojo.require("t.plugins.xy.filter.test");
    dojo.require("t.plugins.xy.detailed.project.test");
    dojo.require("t.plugins.xy.detailed.sample.test");
    dojo.require("t.plugins.xy.detailed.flowcell.test");
    dojo.require("t.plugins.xy.detailed.lane.test");
    dojo.require("t.plugins.xy.filter.test");
}
catch(e) {
    doh.debug(e);
}
