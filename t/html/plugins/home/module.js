dojo.provide("t.plugins.home.module");

try{
    dojo.require("t.plugins.home.github.test");
    dojo.require("t.plugins.home.version.test");
    dojo.require("t.plugins.home.progresspane.test");
}
catch(e) {
    doh.debug(e);
}
