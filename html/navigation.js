var str = "<h3>Flowcells</h3>"; 
document.write(str);
var str = "<ul><li>Search</li>"
document.write(str.link('flowcell.cgi'));
var str = "<li>Active</li></ul>"; 
document.write(str.link('flowcell.cgi?rm=search&status_id=1'));


var str2 = "<h3>Projects</h3>"; 
document.write(str2);
var str2 = "<ul><li>Active</li>"; 
document.write(str2.link('project.cgi?rm=search&status_id=0'));
var str2 = "<li>Search</li>"; 
document.write(str2.link('project.cgi?rm=search_form'));
var str2 = "	<li>Create</li></ul>"; 
document.write(str2.link('project.cgi?rm=create'));


var str2 = "<h3>Samples</h3>"; 
document.write(str2);
var str2 = "<ul><li>Search</li></ul>"; 
document.write(str2.link('sample.cgi?rm=search_form'));


var str2 = "<h3>Builds</h3>"; 
document.write(str2);
var str2 = "<ul><li>Building</li>"; 
document.write(str2.link('buildqueue.cgi?rm=search&status_id=15'));
var str5 = "<li>Undelivered</li></ul>"; 
document.write(str5.link('buildreport.cgi?rm=search&status_id=0')); 


var str5 = "<h3>Requeues</h3>"; 
document.write(str5); 
var str5 = "<ul><li>Create Report</li></ul>"; 
document.write(str5.link('asa')); 

var str5 = "<h3>Special Reports</h3>"; 
document.write(str5); 
var str3 = "<ul><li>FC 2012 report</li></ul>"; 
document.write(str3.link('samplesheet.cgi?rm=get_cols')); 
