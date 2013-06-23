dojo.provide("t.plugins.workflow.module");

try{
    dojo.require("t.plugins.workflow.io.test");
    dojo.require("t.plugins.workflow.runworkflow.test");
    //dojo.require("t.plugins.workflow.runstatus.module");
    dojo.require("t.plugins.workflow.runstatus.duration.test");
    dojo.require("t.plugins.workflow.runstatus.status.test");
    dojo.require("t.plugins.workflow.runstatus.startup.test");
}
catch(e) {
    doh.debug(e);
}
