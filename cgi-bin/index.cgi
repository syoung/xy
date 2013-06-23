#! /usr/bin/perl
use strict; 


print "Content-type:text/html\r\n\r\n";
print '<html>';
print '<head>';
print '<title>SaffronDB</title>';
print '</head>';
print '<body>';
print '<h2>Short scripts </h2>';
print '<a href=samplesheet.cgi?rm=get_cols> flowcells since March 20 2012</a><p> '; 

print '<a href=samplesheet.cgi?rm=get_cols&exclude_delivered=1> flowcells since March 20 2012 excluding delivered samples </a><p> '; 


print '<a href=flowcell.cgi> flowcells sequencing right now </a><p> '; 

print '<a href=project.cgi> list of all the projects  </a><p> '; 

print '</body>';
print '</html>';

