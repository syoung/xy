var Browser=function(_1){
dojo.require("dojo.dnd.Source");
dojo.require("dojo.dnd.Moveable");
dojo.require("dojo.dnd.Mover");
dojo.require("dojo.dnd.move");
dojo.require("dijit.layout.ContentPane");
dojo.require("dijit.layout.BorderContainer");
var _2=_1.refSeqs;
var _3=_1.trackData;
this.deferredFunctions=[];
this.dataRoot=_1.dataRoot;
var _4;
if("dataRoot" in _1){
_4=_1.dataRoot;
}else{
_4="";
}
this.names=new LazyTrie(_4+"/names/lazy-",_4+"/names/root.json");
this.tracks=[];
var _5=this;
_5.isInitialized=false;
dojo.addOnLoad(function(){
dojo.addClass(document.body,"tundra");
_5.container=dojo.byId(_1.containerID);
_5.container.genomeBrowser=_5;
var _6=document.createElement("div");
_5.container.appendChild(_6);
var _7=document.createElement("div");
_7.className="overview";
_7.id="overview";
_6.appendChild(_7);
var _8=_2.reduce(function(a,b){
return a.end>b.end?a:b;
}).end;
var _9=_5.createNavBox(_6,(2*(String(_8).length+(((String(_8).length/3)|0)/2)))+2,_1);
var _a=document.createElement("div");
_5.container.appendChild(_a);
_a.className="dragWindow";
var _b=new dijit.layout.BorderContainer({liveSplitters:false,design:"sidebar",gutters:false},_5.container);
var _c=new dijit.layout.ContentPane({region:"top"},_6);
var _d=new dijit.layout.ContentPane({region:"center"},_a);
_5.locationTrap=document.createElement("div");
_5.locationTrap.className="locationTrap";
_6.appendChild(_5.locationTrap);
_6.style.overflow="hidden";
_5.allRefs={};
for(var i=0;i<_2.length;i++){
_5.allRefs[_2[i].name]=_2[i];
}
var _e=dojo.cookie(_1.containerID+"-refseq");
_5.refSeq=_2[0];
for(var i=0;i<_2.length;i++){
_5.chromList.options[i]=new Option(_2[i].name,_2[i].name);
if(_2[i].name.toUpperCase()==String(_e).toUpperCase()){
_5.refSeq=_5.allRefs[_2[i].name];
_5.chromList.selectedIndex=i;
}
}
dojo.connect(_5.chromList,"onchange",function(_f){
var _10=dojo.fromJson(dojo.cookie(_5.container.id+"-location"))||{};
var _11=_5.allRefs[_5.chromList.options[_5.chromList.selectedIndex].value];
if(_10[_11.name]){
_5.navigateTo(_11.name+":"+_10[_11.name]);
}else{
_5.navigateTo(_11.name+":"+(((_11.start+_11.end)*0.4)|0)+" .. "+(((_11.start+_11.end)*0.6)|0));
}
});
var gv=new GenomeView(_a,250,_5.refSeq,1/200);
_5.view=gv;
_5.viewElem=_a;
_a.view=gv;
dojo.connect(_d,"resize",function(){
gv.sizeInit();
_5.view.locationTrapHeight=dojo.marginBox(_9).h;
gv.showVisibleBlocks();
gv.showFine();
gv.showCoarse();
});
_5.view.locationTrapHeight=dojo.marginBox(_9).h;
dojo.connect(gv,"onFineMove",_5,"onFineMove");
dojo.connect(gv,"onCoarseMove",_5,"onCoarseMove");
var _12=_5.createTrackList(_5.container,_1);
_b.startup();
_5.isInitialized=true;
var _13=dojo.fromJson(dojo.cookie(_5.container.id+"-location"))||{};
if(_1.location){
_5.navigateTo(_1.location);
}else{
if(_13[_5.refSeq.name]){
_5.navigateTo(_5.refSeq.name+":"+_13[_5.refSeq.name]);
}else{
if(_1.defaultLocation){
_5.navigateTo(_1.defaultLocation);
}else{
_5.navigateTo(_5.refSeq.name+":"+((((_5.refSeq.start+_5.refSeq.end)*0.4)|0)+" .. "+(((_5.refSeq.start+_5.refSeq.end)*0.6)|0)));
}
}
}
for(var i=0;i<_5.deferredFunctions.length;i++){
_5.deferredFunctions[i]();
}
_5.deferredFunctions=[];
});
};
Browser.prototype.onFineMove=function(_14,_15){
var _16=this.view.ref.end-this.view.ref.start;
var _17=Math.round((((_14-this.view.ref.start)/_16)*this.view.overviewBox.w)+this.view.overviewBox.l);
var _18=Math.round((((_15-this.view.ref.start)/_16)*this.view.overviewBox.w)+this.view.overviewBox.l);
var _19;
if(dojo.isIE){
_19="top: "+this.view.overviewBox.t+"px;"+"height: "+this.view.overviewBox.h+"px;"+"left: "+_17+"px;"+"width: "+(_18-_17)+"px;"+"border-width: 0px";
}else{
_19="top: "+this.view.overviewBox.t+"px;"+"height: "+this.view.overviewBox.h+"px;"+"left: "+this.view.overviewBox.l+"px;"+"width: "+(_18-_17)+"px;"+"border-width: "+"0px "+(this.view.overviewBox.w-_18)+"px "+this.view.locationTrapHeight+"px "+_17+"px;";
}
this.locationTrap.style.cssText=_19;
};
Browser.prototype.createTrackList=function(_1a,_1b){
var _1c=document.createElement("div");
_1c.style.cssText="width: 10em";
_1a.appendChild(_1c);
var _1d=new dijit.layout.ContentPane({region:"left",splitter:true},_1c);
var _1e=document.createElement("div");
_1e.id="tracksAvail";
_1e.className="container handles";
_1e.style.cssText="width: 100%; height: 100%; overflow-x: hidden; overflow-y: auto;";
_1e.innerHTML="Available Tracks:<br/>(Drag <img src=\""+(_1b.browserRoot?_1b.browserRoot:"")+"img/right_arrow.png\"/> to view)<br/><br/>";
_1c.appendChild(_1e);
var _1f=this;
var _20=function(){
_1f.view.showVisibleBlocks(true);
};
var _21=function(_22,_23){
var _24=document.createElement("div");
_24.className="tracklist-label";
_24.innerHTML=_22.key;
if("avatar"!=_23){
var _25=document.createElement("div");
_25.className="tracklist-container";
_25.appendChild(_24);
_24=_25;
}
_24.id=dojo.dnd.getUniqueId();
return {node:_24,data:_22,type:["track"]};
};
this.trackListWidget=new dojo.dnd.Source(_1e,{creator:_21,accept:["track"],withHandles:false});
var _26=function(_27,_28){
var _29;
if("avatar"==_28){
return _21(_27,_28);
}else{
var _2a={refseq:_1f.refSeq.name};
var url=_27.url.replace(/\{([^}]+)\}/g,function(_2b,_2c){
return _2a[_2c];
});
var _2d=eval(_27.type);
var _2e=new _2d(_27,url,_1f.refSeq,{changeCallback:_20,trackPadding:_1f.view.trackPadding,baseUrl:_1f.dataRoot,charWidth:_1f.view.charWidth,seqHeight:_1f.view.seqHeight});
_29=_1f.view.addTrack(_2e);
}
return {node:_29,data:_27,type:["track"]};
};
this.viewDndWidget=new dojo.dnd.Source(this.view.zoomContainer,{creator:_26,accept:["track"],withHandles:true});
dojo.subscribe("/dnd/drop",function(_2f,_30,_31){
_1f.onVisibleTracksChanged();
});
this.trackListWidget.insertNodes(false,_1b.trackData);
var _32=dojo.cookie(this.container.id+"-tracks");
if(_1b.tracks){
this.showTracks(_1b.tracks);
}else{
if(_32){
this.showTracks(_32);
}else{
if(_1b.defaultTracks){
this.showTracks(_1b.defaultTracks);
}
}
}
return _1e;
};
Browser.prototype.onVisibleTracksChanged=function(){
this.view.updateTrackList();
var _33=dojo.map(this.view.tracks,function(_34){
return _34.name;
});
dojo.cookie(this.container.id+"-tracks",_33.join(","),{expires:60});
this.view.showVisibleBlocks();
};
Browser.prototype.addTracks=function(_35,_36){
if(!this.isInitialized){
var _37=this;
this.deferredFunctions.push(function(){
_37.addTracks(_35,show);
});
return;
}
this.tracks.concat(_35);
if(show||(show===undefined)){
this.showTracks(dojo.map(_35,function(t){
return t.label;
}).join(","));
}
};
Browser.prototype.navigateTo=function(loc){
if(!this.isInitialized){
var _38=this;
this.deferredFunctions.push(function(){
_38.navigateTo(loc);
});
return;
}
loc=dojo.trim(loc);
var _39=String(loc).match(/^(((\S*)\s*:)?\s*(-?[0-9,.]*[0-9])\s*(\.\.|-|\s+))?\s*(-?[0-9,.]+)$/i);
if(_39){
if(_39[3]){
var _3a;
for(ref in this.allRefs){
if((_39[3].toUpperCase()==ref.toUpperCase())||("CHR"+_39[3].toUpperCase()==ref.toUpperCase())||(_39[3].toUpperCase()=="CHR"+ref.toUpperCase())){
_3a=ref;
}
}
if(_3a){
dojo.cookie(this.container.id+"-refseq",_3a,{expires:60});
if(_3a==this.refSeq.name){
this.view.setLocation(this.refSeq,parseInt(_39[4].replace(/[,.]/g,"")),parseInt(_39[6].replace(/[,.]/g,"")));
}else{
var _3b=[];
this.viewDndWidget.forInItems(function(obj,id,map){
_3b.push(obj.data);
});
for(var i=0;i<this.chromList.options.length;i++){
if(this.chromList.options[i].text==_3a){
this.chromList.selectedIndex=i;
}
}
this.refSeq=this.allRefs[_3a];
this.view.setLocation(this.refSeq,parseInt(_39[4].replace(/[,.]/g,"")),parseInt(_39[6].replace(/[,.]/g,"")));
this.viewDndWidget.insertNodes(false,_3b);
this.onVisibleTracksChanged();
}
return;
}
}else{
if(_39[4]){
this.view.setLocation(this.refSeq,parseInt(_39[4].replace(/[,.]/g,"")),parseInt(_39[6].replace(/[,.]/g,"")));
return;
}else{
if(_39[6]){
this.view.centerAtBase(parseInt(_39[6].replace(/[,.]/g,"")));
return;
}
}
}
}
var _38=this;
this.names.exactMatch(loc,function(_3c){
var _3d;
for(var i=0;i<_3c.length;i++){
if(_3c[i][1]==loc){
_3d=_3c[i];
}
}
if(!_3d){
for(var i=0;i<_3c.length;i++){
if(_3c[i][1].toLowerCase()==loc.toLowerCase()){
_3d=_3c[i];
}
}
}
if(!_3d){
_3d=_3c[0];
}
var _3e=_3d[3];
var _3f=_3d[4];
var _40=Math.round((_3f-_3e)*0.2);
_38.navigateTo(_3d[2]+":"+(_3e-_40)+".."+(_3f+_40));
_38.showTracks(_38.names.extra[_3c[0][0]]);
});
};
Browser.prototype.showTracks=function(_41){
if(!this.isInitialized){
var _42=this;
this.deferredFunctions.push(function(){
_42.showTracks(_41);
});
return;
}
var _43=_41.split(",");
var _44=[];
var _42=this;
for(var n=0;n<_43.length;n++){
this.trackListWidget.forInItems(function(obj,id,map){
if(_43[n]==obj.data.label){
_42.viewDndWidget.insertNodes(false,[obj.data]);
_44.push(id);
}
});
}
var _45;
for(var i=0;i<_44.length;i++){
this.trackListWidget.delItem(_44[i]);
_45=dojo.byId(_44[i]);
_45.parentNode.removeChild(_45);
}
this.onVisibleTracksChanged();
};
Browser.prototype.visibleRegion=function(){
return this.view.ref.name+":"+Math.round(this.view.minVisible())+".."+Math.round(this.view.maxVisible());
};
Browser.prototype.visibleTracks=function(){
var _46=dojo.map(this.view.tracks,function(_47){
return _47.name;
});
return _46.join(",");
};
Browser.prototype.onCoarseMove=function(_48,_49){
var _4a=this.view.ref.end-this.view.ref.start;
var _4b=Math.round((((_48-this.view.ref.start)/_4a)*this.view.overviewBox.w)+this.view.overviewBox.l);
var _4c=Math.round((((_49-this.view.ref.start)/_4a)*this.view.overviewBox.w)+this.view.overviewBox.l);
this.view.locationThumb.style.cssText="height: "+(this.view.overviewBox.h-4)+"px; "+"left: "+_4b+"px; "+"width: "+(_4c-_4b)+"px;"+"z-index: 20";
if(!this.isInitialized){
return;
}
var _4d=Util.addCommas(Math.round(_48))+" .. "+Util.addCommas(Math.round(_49));
this.locationBox.value=_4d;
this.goButton.disabled=true;
this.locationBox.blur();
var _4e=dojo.fromJson(dojo.cookie(this.container.id+"-location"));
if((typeof _4e)!="object"){
_4e={};
}
_4e[this.refSeq.name]=_4d;
dojo.cookie(this.container.id+"-location",dojo.toJson(_4e),{expires:60});
document.title=this.refSeq.name+":"+_4d;
};
Browser.prototype.createNavBox=function(_4f,_50,_51){
var _52=this;
var _53=document.createElement("div");
var _54=_51.browserRoot?_51.browserRoot:"";
_53.id="navbox";
_4f.appendChild(_53);
_53.style.cssText="text-align: center; padding: 2px; z-index: 10;";
if(_51.bookmark){
this.link=document.createElement("a");
this.link.appendChild(document.createTextNode("Link"));
this.link.href=window.location.href;
dojo.connect(this,"onCoarseMove",function(){
_52.link.href=_51.bookmark(_52);
});
dojo.connect(this,"onVisibleTracksChanged",function(){
_52.link.href=_51.bookmark(_52);
});
this.link.style.cssText="float: right; clear";
_53.appendChild(this.link);
}
var _55=document.createElement("input");
_55.type="image";
_55.src=_54+"img/slide-left.png";
_55.id="moveLeft";
_55.className="icon nav";
_55.style.height="40px";
dojo.connect(_55,"click",function(_56){
dojo.stopEvent(_56);
_52.view.slide(0.9);
});
_53.appendChild(_55);
var _57=document.createElement("input");
_57.type="image";
_57.src=_54+"img/slide-right.png";
_57.id="moveRight";
_57.className="icon nav";
_57.style.height="40px";
dojo.connect(_57,"click",function(_58){
dojo.stopEvent(_58);
_52.view.slide(-0.9);
});
_53.appendChild(_57);
_53.appendChild(document.createTextNode("    "));
var _59=document.createElement("input");
_59.type="image";
_59.src=_54+"img/zoom-out-2.png";
_59.id="bigZoomOut";
_59.className="icon nav";
_59.style.height="40px";
_53.appendChild(_59);
dojo.connect(_59,"click",function(_5a){
dojo.stopEvent(_5a);
_52.view.zoomOut(undefined,undefined,2);
});
var _5b=document.createElement("input");
_5b.type="image";
_5b.src=_54+"img/zoom-out-1.png";
_5b.id="zoomOut";
_5b.className="icon nav";
_5b.style.height="40px";
dojo.connect(_5b,"click",function(_5c){
dojo.stopEvent(_5c);
_52.view.zoomOut();
});
_53.appendChild(_5b);
var _5d=document.createElement("input");
_5d.type="image";
_5d.src=_54+"img/zoom-in-1.png";
_5d.id="zoomIn";
_5d.className="icon nav";
_5d.style.height="40px";
dojo.connect(_5d,"click",function(_5e){
dojo.stopEvent(_5e);
_52.view.zoomIn();
});
_53.appendChild(_5d);
var _5f=document.createElement("input");
_5f.type="image";
_5f.src=_54+"img/zoom-in-2.png";
_5f.id="bigZoomIn";
_5f.className="icon nav";
_5f.style.height="40px";
dojo.connect(_5f,"click",function(_60){
dojo.stopEvent(_60);
_52.view.zoomIn(undefined,undefined,2);
});
_53.appendChild(_5f);
_53.appendChild(document.createTextNode("    "));
this.chromList=document.createElement("select");
this.chromList.id="chrom";
_53.appendChild(this.chromList);
this.locationBox=document.createElement("input");
this.locationBox.size=_50;
this.locationBox.type="text";
this.locationBox.id="location";
dojo.connect(this.locationBox,"keydown",function(_61){
if(_61.keyCode==dojo.keys.ENTER){
_52.navigateTo(_52.locationBox.value);
_52.goButton.disabled=true;
dojo.stopEvent(_61);
}else{
_52.goButton.disabled=false;
}
});
_53.appendChild(this.locationBox);
this.goButton=document.createElement("button");
this.goButton.appendChild(document.createTextNode("Go"));
this.goButton.disabled=true;
dojo.connect(this.goButton,"click",function(_62){
_52.navigateTo(_52.locationBox.value);
_52.goButton.disabled=true;
dojo.stopEvent(_62);
});
_53.appendChild(this.goButton);
return _53;
};
function FeatureTrack(_1,_2,_3,_4){
Track.call(this,_1.label,_1.key,false,_4.changeCallback);
this.fields={};
this.features=new NCList();
this.refSeq=_3;
this.baseUrl=(_4.baseUrl?_4.baseUrl:"");
this.url=_2;
this.trackBaseUrl=(this.baseUrl+_2).match(/^.+\//);
this.numBins=25;
this.histLabel=false;
this.padding=5;
this.trackPadding=_4.trackPadding;
this.trackMeta=_1;
this.load(this.baseUrl+_2);
var _5=this;
};
FeatureTrack.prototype=new Track("");
FeatureTrack.prototype.loadSuccess=function(_6){
var _7=new Date().getTime();
this.count=_6.featureCount;
this.fields={};
for(var i=0;i<_6.headers.length;i++){
this.fields[_6.headers[i]]=i;
}
this.subFields={};
if(_6.subfeatureHeaders){
for(var i=0;i<_6.subfeatureHeaders.length;i++){
this.subFields[_6.subfeatureHeaders[i]]=i;
}
}
this.features.importExisting(_6.featureNCList,_6.sublistIndex,_6.lazyIndex,this.trackBaseUrl,_6.lazyfeatureUrlTemplate);
if(_6.subfeatureArray){
this.subfeatureArray=new LazyArray(_6.subfeatureArray,this.trackBaseUrl);
}
this.histScale=4*(_6.featureCount/this.refSeq.length);
this.labelScale=50*(_6.featureCount/this.refSeq.length);
this.subfeatureScale=80*(_6.featureCount/this.refSeq.length);
this.className=_6.className;
this.subfeatureClasses=_6.subfeatureClasses;
this.arrowheadClass=_6.arrowheadClass;
this.urlTemplate=_6.urlTemplate;
this.histogramMeta=_6.histogramMeta;
for(var i=0;i<this.histogramMeta.length;i++){
this.histogramMeta[i].lazyArray=new LazyArray(this.histogramMeta[i].arrayParams,this.trackBaseUrl);
}
this.histStats=_6.histStats;
this.histBinBases=_6.histBinBases;
if(_6.clientConfig){
var cc=_6.clientConfig;
var _8=_6.featureCount/this.refSeq.length;
this.histScale=(cc.histScale?cc.histScale:4)*_8;
this.labelScale=(cc.labelScale?cc.labelScale:50)*_8;
this.subfeatureScale=(cc.subfeatureScale?cc.subfeatureScale:80)*_8;
if(cc.featureCss){
this.featureCss=cc.featureCss;
}
if(cc.histCss){
this.histCss=cc.histCss;
}
if(cc.featureCallback){
try{
this.featureCallback=eval("("+cc.featureCallback+")");
}
catch(e){
//console.log("eval failed for featureCallback on track "+this.name+": "+cc.featureCallback);
}
}
}
var _9=this.fields;
if(!_6.urlTemplate){
this.onFeatureClick=function(_a){
_a=_a||window.event;
if(_a.shiftKey){
return;
}
var _b=(_a.currentTarget||_a.srcElement);
if(!_b.feature){
_b=_b.parentElement;
}
if(!_b.feature){
return;
}
var _c=_b.feature;
alert("clicked on feature\nstart: "+_c[_9["start"]]+", end: "+_c[_9["end"]]+", strand: "+_c[_9["strand"]]+", label: "+_c[_9["name"]]+", ID: "+_c[_9["id"]]);
};
}
this.setLoaded();
};
FeatureTrack.prototype.setViewInfo=function(_d,_e,_f,_10,_11,_12,_13){
Track.prototype.setViewInfo.apply(this,[_d,_e,_f,_10,_11,_12,_13]);
this.setLabel(this.key);
};
FeatureTrack.prototype.fillHist=function(_14,_15,_16,_17,_18){
var _19=(_17-_16)/this.numBins;
var _1a=2;
var _1b=false;
for(var i=0;i<this.histStats.length;i++){
if(this.histStats[i].bases>=_19){
_1b=((this.histStats[i].mean/this.histStats[i].max)<0.01);
_1a=100/(_1b?Math.log(this.histStats[i].max):this.histStats[i].max);
break;
}
}
var _1c=this;
var _1d=function(_1e){
var _1f=0;
for(var bin=0;bin<_1c.numBins;bin++){
if(typeof _1e[bin]=="number"&&isFinite(_1e[bin])){
_1f=Math.max(_1f,_1e[bin]);
}
}
var _20;
for(var bin=0;bin<_1c.numBins;bin++){
if(!(typeof _1e[bin]=="number"&&isFinite(_1e[bin]))){
continue;
}
_20=document.createElement("div");
_20.className=_1c.className+"-hist";
_20.style.cssText="left: "+((bin/_1c.numBins)*100)+"%; "+"height: "+(_1a*(_1b?Math.log(_1e[bin]):_1e[bin]))+"px;"+"bottom: "+_1c.trackPadding+"px;"+"width: "+(((1/_1c.numBins)*100)-(100/_18))+"%;"+(_1c.histCss?_1c.histCss:"");
if(Util.is_ie6){
_20.appendChild(document.createComment());
}
_15.appendChild(_20);
}
_1c.heightUpdate(_1a*(_1b?Math.log(_1f):_1f),_14);
};
var _21=this.histogramMeta[0];
for(var i=0;i<this.histogramMeta.length;i++){
if(_19>=this.histogramMeta[i].basesPerBin){
_21=this.histogramMeta[i];
}
}
var _22=_19/_21.basesPerBin;
if((_22>0.9)&&(Math.abs(_22-Math.round(_22))<0.0001)){
var _23=Math.floor(_16/_21.basesPerBin);
_22=Math.round(_22);
var _24=[];
for(var bin=0;bin<this.numBins;bin++){
_24[bin]=0;
}
_21.lazyArray.range(_23,_23+(_22*this.numBins),function(i,val){
_24[Math.floor((i-_23)/_22)]+=val;
},function(){
_1d(_24);
});
}else{
this.features.histogram(_16,_17,this.numBins,_1d);
}
};
FeatureTrack.prototype.endZoom=function(_25,_26){
if(_25<this.histScale){
this.setLabel(this.key+"<br>per "+Math.round(_26/this.numBins)+"bp");
}else{
this.setLabel(this.key);
}
this.clear();
};
FeatureTrack.prototype.fillBlock=function(_27,_28,_29,_2a,_2b,_2c,_2d,_2e,_2f,_30){
if(_2d<this.histScale){
this.fillHist(_27,_28,_2b,_2c,_2e,_2f,_30);
}else{
this.fillFeatures(_27,_28,_29,_2a,_2b,_2c,_2d,_2f,_30);
}
};
FeatureTrack.prototype.cleanupBlock=function(_31){
if(_31&&_31.featureLayout){
_31.featureLayout.cleanup();
}
};
FeatureTrack.prototype.transfer=function(_32,_33,_34,_35,_36){
if(!(_32&&_33)){
return;
}
if(!_32.featureLayout){
return;
}
var _37=_33.startBase;
var _38=_33.endBase;
var _39=_38-_37;
var _3a;
var _3b=(_32.startBase<_33.startBase)?_32.featureLayout.rightOverlaps:_32.featureLayout.leftOverlaps;
for(var i=0;i<_3b.length;i++){
_3a=_32.featureNodes[_3b[i].id];
if(_3a&&("label" in _3a)){
_3a.label.parentNode.removeChild(_3a.label);
}
if(_3a&&_3a.feature){
if((_3a.layoutEnd>_37)&&(_3a.feature[this.fields["start"]]<_38)){
_32.removeChild(_3a);
delete _32.featureNodes[_3b[i].id];
var _3c=this.renderFeature(_3a.feature,_3b[i].id,_33,_34,_35,_36);
_33.appendChild(_3c);
}
}
}
};
FeatureTrack.prototype.fillFeatures=function(_3d,_3e,_3f,_40,_41,_42,_43,_44,_45){
var _46=new Layout(_41,_42);
_3e.featureLayout=_46;
_3e.featureNodes={};
_3e.style.backgroundColor="#ddd";
var _47=false;
if(_3f&&_3f.featureLayout){
_3f.featureLayout.setRightLayout(_46);
_46.setLeftLayout(_3f.featureLayout);
}
if(_40&&_40.featureLayout){
_40.featureLayout.setLeftLayout(_46);
_46.setRightLayout(_40.featureLayout);
_47=true;
}
if(!this.haveMeasurements){
this.measureStyles();
this.haveMeasurements=true;
}
var _48=this;
var _49=function(_4a,_4b){
var _4c=_4b.join(",");
if(_46.hasSeen(_4c)){
return;
}
var _4d=_48.renderFeature(_4a,_4c,_3e,_43,_44,_45);
_3e.appendChild(_4d);
};
var _4e=_47?_42:_41;
var _4f=_47?_41:_42;
this.features.iterate(_4e,_4f,_49,function(){
_3e.style.backgroundColor="";
_48.heightUpdate(_46.totalHeight,_3d);
});
};
FeatureTrack.prototype.measureStyles=function(){
var _50=document.createElement("div");
_50.className="feature-label";
_50.style.height="auto";
_50.style.visibility="hidden";
_50.appendChild(document.createTextNode("1234567890"));
document.body.appendChild(_50);
this.nameHeight=_50.clientHeight;
this.nameWidth=_50.clientWidth/10;
document.body.removeChild(_50);
var _51;
_50=document.createElement("div");
_50.className=this.className+" plus-"+this.className+" plus-"+this.className+"1";
if(this.featureCss){
_50.style.cssText=this.featureCss;
}
_50.style.visibility="hidden";
if(Util.is_ie6){
_50.appendChild(document.createComment("foo"));
}
document.body.appendChild(_50);
_51=dojo.marginBox(_50);
this.glyphHeight=Math.round(_51.h+2);
this.padding+=_51.w;
document.body.removeChild(_50);
if(this.arrowheadClass){
var ah=document.createElement("div");
ah.className="plus-"+this.arrowheadClass;
if(Util.is_ie6){
ah.appendChild(document.createComment("foo"));
}
document.body.appendChild(ah);
_51=dojo.marginBox(ah);
this.plusArrowWidth=_51.w;
ah.className="minus-"+this.arrowheadClass;
_51=dojo.marginBox(ah);
this.minusArrowWidth=_51.w;
document.body.removeChild(ah);
}
};
FeatureTrack.prototype.renderFeature=function(_52,_53,_54,_55,_56,_57){
var _58=this.fields;
var _59=_52[_58["end"]];
var _5a=_52[_58["start"]];
if(this.arrowheadClass){
switch(_52[_58["strand"]]){
case 1:
_59+=(this.plusArrowWidth/_55);
break;
case -1:
_5a-=(this.minusArrowWidth/_55);
break;
}
}
if(_55>this.labelScale){
_59=Math.max(_59,_52[_58["start"]]+(((_58["name"]&&_52[_58["name"]])?_52[_58["name"]].length:0)*(this.nameWidth/_55)));
}
_59+=Math.max(1,this.padding/_55);
var _5b=this.glyphHeight+2+((_58["name"]&&(_55>this.labelScale))?this.nameHeight:0);
var top=_54.featureLayout.addRect(_53,_5a,_59,_5b);
var _5c;
var _5d=this.featureUrl(_52);
if(_5d){
_5c=document.createElement("a");
_5c.href=_5d;
_5c.target="_new";
}else{
_5c=document.createElement("div");
_5c.onclick=this.onFeatureClick;
}
_5c.feature=_52;
_5c.layoutEnd=_59;
_54.featureNodes[_53]=_5c;
switch(_52[_58["strand"]]){
case 1:
_5c.className="plus-"+this.className;
break;
case 0:
case null:
case undefined:
_5c.className=this.className;
break;
case -1:
_5c.className="minus-"+this.className;
break;
}
if((_58["phase"]!==undefined)&&(_52[_58["phase"]]!==null)){
_5c.className=_5c.className+_52[_58["phase"]];
}
var _5e=Math.max(_52[_58["start"]],_56);
var _5f=Math.min(_52[_58["end"]],_57);
var _60=_54.endBase-_54.startBase;
_5c.style.cssText="left:"+(100*(_5e-_54.startBase)/_60)+"%;"+"top:"+top+"px;"+" width:"+(100*((_5f-_5e)/_60))+"%;"+(this.featureCss?this.featureCss:"");
if(this.featureCallback){
this.featureCallback(_52,_58,_5c);
}
if(this.arrowheadClass){
var ah=document.createElement("div");
switch(_52[_58["strand"]]){
case 1:
ah.className="plus-"+this.arrowheadClass;
ah.style.cssText="left: 100%; top: 0px;";
_5c.appendChild(ah);
break;
case -1:
ah.className="minus-"+this.arrowheadClass;
ah.style.cssText="left: "+(-this.minusArrowWidth)+"px; top: 0px;";
_5c.appendChild(ah);
break;
}
}
if((_55>this.labelScale)&&_58["name"]&&_52[_58["name"]]){
var _61;
if(_5d){
_61=document.createElement("a");
_61.href=_5d;
_61.target=_5c.target;
}else{
_61=document.createElement("div");
_61.onclick=this.onFeatureClick;
}
_61.className="feature-label";
_61.appendChild(document.createTextNode(_52[_58["name"]]));
_61.style.cssText="left: "+(100*(_52[_58["start"]]-_54.startBase)/_60)+"%; "+"top: "+(top+this.glyphHeight)+"px;";
_5c.label=_61;
_61.feature=_52;
_54.appendChild(_61);
}
if(_58["subfeatures"]&&(_55>this.subfeatureScale)&&_52[_58["subfeatures"]]&&_52[_58["subfeatures"]].length>0){
for(var i=0;i<_52[_58["subfeatures"]].length;i++){
this.renderSubfeature(_52,_5c,_52[_58["subfeatures"]][i],_5e,_5f);
}
}
if(Util.is_ie6){
_5c.appendChild(document.createComment());
}
return _5c;
};
FeatureTrack.prototype.featureUrl=function(_62){
var _63=true;
var _64=this.fields;
if(this.urlTemplate){
var _65=this.urlTemplate.replace(/\{([^}]+)\}/g,function(_66,_67){
if(_62[_64[_67]]!=undefined){
return _62[_64[_67]];
}else{
_63=false;
}
return 0;
});
if(_63){
return _65;
}
}
return undefined;
};
FeatureTrack.prototype.renderSubfeature=function(_68,_69,_6a,_6b,_6c){
var _6d=_6a[this.subFields["start"]];
var _6e=_6a[this.subFields["end"]];
var _6f=_6c-_6b;
var _70=document.createElement("div");
if(this.subfeatureClasses){
var _71=this.subfeatureClasses[_6a[this.subFields["type"]]];
switch(_6a[this.subFields["strand"]]){
case 1:
_70.className="plus-"+_71;
break;
case 0:
case null:
case undefined:
_70.className=_71;
break;
case -1:
_70.className="minus-"+_71;
break;
}
}
if((_6e<=_6b)||(_6d>=_6c)){
return;
}
if(Util.is_ie6){
_70.appendChild(document.createComment());
}
_70.style.cssText="left: "+(100*((_6d-_6b)/_6f))+"%;"+"top: 0px;"+"width: "+(100*((_6e-_6d)/_6f))+"%;";
if(this.featureCallback){
this.featureCallback(_6a,this.subFields,_70);
}
_69.appendChild(_70);
};
function Animation(_1,_2,_3){
if(_1===undefined){
return;
}
if("animation" in _1){
_1.animation.stop();
}
this.index=0;
this.time=_3;
this.subject=_1;
this.callback=_2;
var _4=this;
this.animFunction=function(){
_4.animate();
};
this.animID=setTimeout(this.animFunction,33);
this.frames=0;
_1.animation=this;
};
Animation.prototype.animate=function(){
if(this.finished){
this.stop();
return;
}
var _5=33;
var _6=0;
if(!("startTime" in this)){
this.startTime=(new Date()).getTime();
}else{
_6=(new Date()).getTime()-this.startTime;
_5=Math.max(33,_6/this.frames);
}
if(_6<this.time){
this.step(_6/this.time);
this.frames++;
}else{
this.step(1);
this.finished=true;
}
this.animID=setTimeout(this.animFunction,_5);
};
Animation.prototype.stop=function(){
clearTimeout(this.animID);
delete this.subject.animation;
this.callback(this);
};
function Slider(_7,_8,_9,_a){
Animation.call(this,_7,_8,_9);
this.slideStart=_7.getX();
this.slideDistance=_a;
};
Slider.prototype=new Animation();
Slider.prototype.step=function(_b){
var _c=(this.slideStart-(this.slideDistance*((-0.5*Math.cos(_b*Math.PI))+0.5)))|0;
_c=Math.max(Math.min(this.subject.maxLeft-this.subject.offset,_c),this.subject.minLeft-this.subject.offset);
this.subject.setX(_c);
};
function Zoomer(_d,_e,_f,_10,_11){
Animation.call(this,_e,_f,_10);
this.toZoom=_e.zoomContainer;
var _12=this.toZoom.clientWidth;
this.initialWidth=_12;
this.width0=_12*Math.min(1,_d);
var _13=_12*Math.max(1,_d);
this.distance=_13-this.width0;
this.zoomingIn=_d>1;
this.center=(_e.getX()+(_e.elem.clientWidth*_11))/_e.scrollContainer.clientWidth;
this.initialX=this.subject.getX();
this.initialLeft=parseInt(this.toZoom.style.left);
};
Zoomer.prototype=new Animation();
Zoomer.prototype.step=function(pos){
var _14=this.zoomingIn?pos:1-pos;
var _15=((_14*_14)*this.distance)+this.width0;
var _16=(this.center*this.initialWidth)-(this.center*_15);
this.toZoom.style.width=_15+"px";
this.toZoom.style.left=(this.initialLeft+_16)+"px";
var _17=this.toZoom.offsetTop;
this.subject.updateTrackLabels(this.initialX-_16);
};
function GenomeView(_18,_19,_1a,_1b){
var _1c=document.createElement("div");
_1c.className="sequence";
_1c.style.visibility="hidden";
var _1d="12345678901234567890123456789012345678901234567890";
_1c.appendChild(document.createTextNode(_1d));
_18.appendChild(_1c);
this.charWidth=_1c.clientWidth/_1d.length;
this.seqHeight=_1c.clientHeight;
_18.removeChild(_1c);
var _1e=document.createElement("div");
_1e.className="pos-label";
_1e.style.visibility="hidden";
_1e.appendChild(document.createTextNode("42"));
_18.appendChild(_1e);
this.posHeight=_1e.clientHeight;
this.topSpace=1.5*this.posHeight;
_18.removeChild(_1e);
this.ref=_1a;
this.pxPerBp=_1b;
this.stripeWidth=_19;
this.elem=_18;
this.scrollContainer=document.createElement("div");
this.scrollContainer.id="container";
this.scrollContainer.style.cssText="position: absolute; left: 0px; top: 0px;";
_18.appendChild(this.scrollContainer);
this.zoomContainer=document.createElement("div");
this.zoomContainer.id="zoomContainer";
this.zoomContainer.style.cssText="position: absolute; left: 0px; top: 0px; height: 100%;";
this.scrollContainer.appendChild(this.zoomContainer);
this.regularStripe=_19;
this.fullZoomStripe=this.charWidth*(_19/10);
this.overview=dojo.byId("overview");
this.overviewBox=dojo.marginBox(this.overview);
this.tracks=[];
this.uiTracks=[];
this.trackIndices={};
this.sizeInit();
this.offset=0;
this.maxLeft=this.bpToPx(this.ref.end)-this.dim.width;
this.minLeft=this.bpToPx(this.ref.start);
this.trackPadding=20;
this.drawMargin=0.2;
this.slideTimeMultiple=0.8;
this.trackHeights=[];
this.trackTops=[];
this.trackLabels=[];
this.waitElems=[dojo.byId("moveLeft"),dojo.byId("moveRight"),dojo.byId("zoomIn"),dojo.byId("zoomOut"),dojo.byId("bigZoomIn"),dojo.byId("bigZoomOut"),document.body,_18];
this.prevCursors=[];
this.locationThumb=document.createElement("div");
this.locationThumb.className="locationThumb";
this.overview.appendChild(this.locationThumb);
this.locationThumbMover=new dojo.dnd.move.parentConstrainedMoveable(this.locationThumb,{area:"margin",within:true});
dojo.connect(this.locationThumbMover,"onMoveStop",this,"thumbMoved");
var _1f=this;
var _20=dojo.isIE;
if(_20){
_1f.x=-parseInt(_1f.scrollContainer.style.left);
_1f.y=-parseInt(_1f.scrollContainer.style.top);
_1f.getX=function(){
return _1f.x;
};
_1f.getY=function(){
return _1f.y;
};
_1f.getPosition=function(){
return {x:_1f.x,y:_1f.y};
};
_1f.rawSetX=function(x){
_1f.scrollContainer.style.left=-x+"px";
_1f.x=x;
};
_1f.setX=function(x){
_1f.x=Math.max(Math.min(_1f.maxLeft-_1f.offset,x),_1f.minLeft-_1f.offset);
_1f.x=Math.round(_1f.x);
_1f.updateTrackLabels(_1f.x);
_1f.showFine();
_1f.scrollContainer.style.left=-_1f.x+"px";
};
_1f.rawSetY=function(y){
_1f.scrollContainer.style.top=-y+"px";
_1f.y=y;
};
_1f.setY=function(y){
_1f.y=Math.min((y<0?0:y),_1f.containerHeight-_1f.dim.height);
_1f.y=Math.round(_1f.y);
_1f.updatePosLabels(_1f.y);
_1f.scrollContainer.style.top=-_1f.y+"px";
};
_1f.rawSetPosition=function(pos){
_1f.scrollContainer.style.left=-pos.x+"px";
_1f.scrollContainer.style.top=-pos.y+"px";
};
_1f.setPosition=function(pos){
_1f.x=Math.max(Math.min(_1f.maxLeft-_1f.offset,pos.x),_1f.minLeft-_1f.offset);
_1f.y=Math.min((pos.y<0?0:pos.y),_1f.containerHeight-_1f.dim.height);
_1f.x=Math.round(_1f.x);
_1f.y=Math.round(_1f.y);
_1f.updateTrackLabels(_1f.x);
_1f.updatePosLabels(_1f.y);
_1f.showFine();
_1f.scrollContainer.style.left=-_1f.x+"px";
_1f.scrollContainer.style.top=-_1f.y+"px";
};
}else{
_1f.x=_1f.elem.scrollLeft;
_1f.y=_1f.elem.scrollTop;
_1f.getX=function(){
return _1f.x;
};
_1f.getY=function(){
return _1f.y;
};
_1f.getPosition=function(){
return {x:_1f.x,y:_1f.y};
};
_1f.rawSetX=function(x){
_1f.elem.scrollLeft=x;
_1f.x=x;
};
_1f.setX=function(x){
_1f.x=Math.max(Math.min(_1f.maxLeft-_1f.offset,x),_1f.minLeft-_1f.offset);
_1f.x=Math.round(_1f.x);
_1f.updateTrackLabels(_1f.x);
_1f.showFine();
_1f.elem.scrollLeft=_1f.x;
};
_1f.rawSetY=function(y){
_1f.elem.scrollTop=y;
_1f.y=y;
};
_1f.rawSetPosition=function(pos){
_1f.elem.scrollLeft=pos.x;
_1f.x=pos.x;
_1f.elem.scrollTop=pos.y;
_1f.y=pos.y;
};
_1f.setY=function(y){
_1f.y=Math.min((y<0?0:y),_1f.containerHeight-_1f.dim.height);
_1f.y=Math.round(_1f.y);
_1f.updatePosLabels(_1f.y);
_1f.elem.scrollTop=_1f.y;
};
_1f.setPosition=function(pos){
_1f.x=Math.max(Math.min(_1f.maxLeft-_1f.offset,pos.x),_1f.minLeft-_1f.offset);
_1f.y=Math.min((pos.y<0?0:pos.y),_1f.containerHeight-_1f.dim.height);
_1f.x=Math.round(_1f.x);
_1f.y=Math.round(_1f.y);
_1f.updateTrackLabels(_1f.x);
_1f.updatePosLabels(_1f.y);
_1f.showFine();
_1f.elem.scrollLeft=_1f.x;
_1f.elem.scrollTop=_1f.y;
};
}
_1f.dragEnd=function(_21){
dojo.forEach(_1f.dragEventHandles,dojo.disconnect);
_1f.dragging=false;

/* CHANGED */
//_1f.elem.style.cursor="url(\"openhand.cur\"), move";
_1f.elem.style.cursor="url(\"plugins/view/jbrowse/openhand.cur\"), move";

document.body.style.cursor="default";
dojo.stopEvent(_21);
_1f.showCoarse();
_1f.scrollUpdate();
_1f.showVisibleBlocks(true);
};
var _22=document.body.parentNode;
var _23=document.body;
_1f.checkDragOut=function(_24){
if(!(_24.relatedTarget||_24.toElement)||(_22===(_24.relatedTarget||_24.toElement))||(_23===(_24.relatedTarget||_24.toElement))){
_1f.dragEnd(_24);
}
};
_1f.dragMove=function(_25){
_1f.setPosition({x:_1f.winStartPos.x-(_25.clientX-_1f.dragStartPos.x),y:_1f.winStartPos.y-(_25.clientY-_1f.dragStartPos.y)});
dojo.stopEvent(_25);
};
_1f.mouseDown=function(_26){
if("animation" in _1f){
if(_1f.animation instanceof Zoomer){
dojo.stopEvent(_26);
return;
}else{
_1f.animation.stop();
}
}
if(Util.isRightButton(_26)){
return;
}
dojo.stopEvent(_26);
if(_26.shiftKey||_26.ctrlKey){
return;
}
_1f.dragEventHandles=[dojo.connect(document.body,"mouseup",_1f.dragEnd),dojo.connect(document.body,"mousemove",_1f.dragMove),dojo.connect(document.body,"mouseout",_1f.checkDragOut)];
_1f.dragging=true;
_1f.dragStartPos={x:_26.clientX,y:_26.clientY};
_1f.winStartPos=_1f.getPosition();
//document.body.style.cursor="url(\"closedhand.cur\"), move";
document.body.style.cursor="url(\"plugins/view/jbrowse/closedhand.cur\"), move";
_1f.elem.style.cursor="url(\"closedhand.cur\"), move";
};
dojo.connect(_1f.elem,"mousedown",_1f.mouseDown);
dojo.connect(_1f.elem,"dblclick",function(_27){
if(_1f.dragging){
return;
}
if("animation" in _1f){
return;
}
var _28=(_27.pageX-dojo.coords(_1f.elem,true).x)/_1f.dim.width;
if(_27.shiftKey){
_1f.zoomOut(_27,_28,2);
}else{
_1f.zoomIn(_27,_28,2);
}
dojo.stopEvent(_27);
});
_1f.afterSlide=function(){
_1f.showCoarse();
_1f.scrollUpdate();
_1f.showVisibleBlocks(true);
};
_1f.zoomCallback=function(){
_1f.zoomUpdate();
};
var _29=null;
var _2a=function(){
_1f.showVisibleBlocks(true);
_29=null;
};
_1f.wheelScroll=function(e){
var _2b=_1f.getY();
var _2c=Math.min(Math.max(0,_2b-60*Util.wheel(e)),_1f.containerHeight-_1f.dim.height);
_1f.setY(_2c);
if(_29){
clearTimeout(_29);
}
_29=setTimeout(_2a,100);
dojo.stopEvent(e);
};
dojo.connect(_1f.scrollContainer,"mousewheel",_1f.wheelScroll,false);
dojo.connect(_1f.scrollContainer,"DOMMouseScroll",_1f.wheelScroll,false);
var _2d=document.createElement("div");
_2d.className="track";
_2d.style.height=this.posHeight+"px";
_2d.id="static_track";
this.staticTrack=new StaticTrack("static_track","pos-label",this.posHeight);
this.staticTrack.setViewInfo(function(_2e){
},this.stripeCount,_2d,undefined,this.stripePercent,this.stripeWidth,this.pxPerBp);
this.zoomContainer.appendChild(_2d);
this.waitElems.push(_2d);
var _2f=document.createElement("div");
_2f.className="track";
_2f.style.cssText="top: 0px; height: 100%;";
_2f.id="gridtrack";
var _30=new GridTrack("gridtrack");
_30.setViewInfo(function(_31){
},this.stripeCount,_2f,undefined,this.stripePercent,this.stripeWidth,this.pxPerBp);
this.zoomContainer.appendChild(_2f);
this.uiTracks=[this.staticTrack,_30];
dojo.forEach(this.uiTracks,function(_32){
_32.showRange(0,this.stripeCount-1,Math.round(this.pxToBp(this.offset)),Math.round(this.stripeWidth/this.pxPerBp),this.pxPerBp);
},this);
this.zoomContainer.style.paddingTop=this.topSpace+"px";
this.addOverviewTrack(new StaticTrack("overview_loc_track","overview-pos",this.overviewPosHeight));
//document.body.style.cursor="url(\"closedhand.cur\")";
document.body.style.cursor="url(\"plugins/view/jbrowse/closedhand.cur\")";
document.body.style.cursor="default";
this.showFine();
this.showCoarse();
};
GenomeView.prototype.slide=function(_33){
if(this.animation){
this.animation.stop();
}
this.trimVertical();
new Slider(this,this.afterSlide,Math.abs(_33)*this.dim.width*this.slideTimeMultiple+200,_33*this.dim.width);
};
GenomeView.prototype.highlightRegions=function(_34){
};
GenomeView.prototype.setLocation=function(_35,_36,_37){
if(_36===undefined){
_36=this.minVisible();
}
if(_37===undefined){
_37=this.maxVisible();
}
if((_36<_35.start)||(_36>_35.end)){
_36=_35.start;
}
if((_37<_35.start)||(_37>_35.end)){
_37=_35.end;
}
if(this.ref!=_35){
this.ref=_35;
var _38=function(_39){
if(_39.div&&_39.div.parentNode){
_39.div.parentNode.removeChild(_39.div);
}
};
dojo.forEach(this.tracks,_38);
dojo.forEach(this.uiTracks,function(_3a){
_3a.clear();
});
this.overviewTrackIterate(_38);
this.addOverviewTrack(new StaticTrack("overview_loc_track","overview-pos",this.overviewPosHeight));
this.sizeInit();
this.setY(0);
this.containerHeight=this.topSpace;
}
this.pxPerBp=Math.min(this.dim.width/(_37-_36),this.charWidth);
this.curZoom=Util.findNearest(this.zoomLevels,this.pxPerBp);
if(Math.abs(this.pxPerBp-this.zoomLevels[this.zoomLevels.length-1])<0.2){
//console.log("nudging zoom level from %d to %d",this.pxPerBp,this.zoomLevels[this.zoomLevels.length-1]);
this.pxPerBp=this.zoomLevels[this.zoomLevels.length-1];
}
this.stripeWidth=(this.stripeWidthForZoom(this.curZoom)/this.zoomLevels[this.curZoom])*this.pxPerBp;
this.instantZoomUpdate();
this.centerAtBase((_36+_37)/2,true);
};
GenomeView.prototype.stripeWidthForZoom=function(_3b){
if((this.zoomLevels.length-1)==_3b){
return this.fullZoomStripe;
}else{
if(0==_3b){
return this.minZoomStripe;
}else{
return this.regularStripe;
}
}
};
GenomeView.prototype.instantZoomUpdate=function(){
this.scrollContainer.style.width=(this.stripeCount*this.stripeWidth)+"px";
this.zoomContainer.style.width=(this.stripeCount*this.stripeWidth)+"px";
this.maxOffset=this.bpToPx(this.ref.end)-this.stripeCount*this.stripeWidth;
this.maxLeft=this.bpToPx(this.ref.end)-this.dim.width;
this.minLeft=this.bpToPx(this.ref.start);
};
GenomeView.prototype.centerAtBase=function(_3c,_3d){
_3c=Math.min(Math.max(_3c,this.ref.start),this.ref.end);
if(_3d){
var _3e=this.bpToPx(_3c);
var _3f=this.stripeCount*this.stripeWidth;
var _40=Math.floor((_3e-(_3f/2))/this.stripeWidth);
this.offset=_40*this.stripeWidth;
this.setX(_3e-this.offset-(this.dim.width/2));
this.trackIterate(function(_41){
_41.clear();
});
this.showVisibleBlocks(true);
this.showCoarse();
}else{
var _42=this.pxToBp(this.x+this.offset);
var _43=(this.dim.width/this.pxPerBp)/2;
var _44=_42+_43+_43;
var _45=_42+_43;
if((_3c>=(_42-_43))&&(_3c<=(_44+_43))){
if(this.animation){
this.animation.stop();
}
var _46=(_45-_3c)*this.pxPerBp;
this.trimVertical();
new Slider(this,this.afterSlide,Math.abs(_46)*this.slideTimeMultiple+200,_46);
}else{
this.centerAtBase(_3c,true);
}
}
};
GenomeView.prototype.minVisible=function(){
return this.pxToBp(this.x+this.offset);
};
GenomeView.prototype.maxVisible=function(){
return this.pxToBp(this.x+this.offset+this.dim.width);
};
GenomeView.prototype.showFine=function(){
this.onFineMove(this.minVisible(),this.maxVisible());
};
GenomeView.prototype.showCoarse=function(){
this.onCoarseMove(this.minVisible(),this.maxVisible());
};
GenomeView.prototype.onFineMove=function(){
};
GenomeView.prototype.onCoarseMove=function(){
};
GenomeView.prototype.thumbMoved=function(_47){
var _48=parseInt(this.locationThumb.style.left);
var _49=parseInt(this.locationThumb.style.width);
var _4a=_48+(_49/2);
this.centerAtBase(((_4a/this.overviewBox.w)*(this.ref.end-this.ref.start))+this.ref.start);
};
GenomeView.prototype.checkY=function(y){
return Math.min((y<0?0:y),this.containerHeight-this.dim.height);
};
GenomeView.prototype.updatePosLabels=function(_4b){
if(_4b===undefined){
_4b=this.getY();
}
this.staticTrack.div.style.top=_4b+"px";
};
GenomeView.prototype.updateTrackLabels=function(_4c){
if(_4c===undefined){
_4c=this.getX();
}
for(var i=0;i<this.trackLabels.length;i++){
this.trackLabels[i].style.left=_4c+"px";
}
};
GenomeView.prototype.showWait=function(){
var _4d=[];
for(var i=0;i<this.waitElems.length;i++){
_4d[i]=this.waitElems[i].style.cursor;
this.waitElems[i].style.cursor="wait";
}
this.prevCursors.push(_4d);
};
GenomeView.prototype.showDone=function(){
var _4e=this.prevCursors.pop();
for(var i=0;i<this.waitElems.length;i++){
this.waitElems[i].style.cursor=_4e[i];
}
};
GenomeView.prototype.pxToBp=function(_4f){
return _4f/this.pxPerBp;
};
GenomeView.prototype.bpToPx=function(bp){
return bp*this.pxPerBp;
};
GenomeView.prototype.sizeInit=function(){
this.dim={width:this.elem.clientWidth,height:this.elem.clientHeight};
this.overviewBox=dojo.marginBox(this.overview);
this.zoomLevels=[1/500000,1/200000,1/100000,1/50000,1/20000,1/10000,1/5000,1/2000,1/1000,1/500,1/200,1/100,1/50,1/20,1/10,1/5,1/2,1,2,5,this.charWidth];
while(((this.ref.end-this.ref.start)*this.zoomLevels[0])<this.dim.width){
this.zoomLevels.shift();
}
this.zoomLevels.unshift(this.dim.width/(this.ref.end-this.ref.start));
this.minZoomStripe=this.regularStripe*(this.zoomLevels[0]/this.zoomLevels[1]);
this.curZoom=0;
while(this.pxPerBp>this.zoomLevels[this.curZoom]){
this.curZoom++;
}
this.maxLeft=this.bpToPx(this.ref.end)-this.dim.width;
delete this.stripePercent;
var _50=[20,10,5,4,2,1];
for(var i=0;i<_50.length;i++){
if(((100/_50[i])*(this.regularStripe*0.7))>((this.dim.width*3)+this.regularStripe)){
this.stripePercent=_50[i];
break;
}
}
if(this.stripePercent===undefined){
//console.warn("stripeWidth too small: "+this.stripeWidth+", "+this.dim.width);
this.stripePercent=1;
}
var _51;
var _52=this.stripeCount;
if(_52){
_51=this.getX();
}
this.stripeCount=Math.round(100/this.stripePercent);
this.scrollContainer.style.width=(this.stripeCount*this.stripeWidth)+"px";
this.zoomContainer.style.width=(this.stripeCount*this.stripeWidth)+"px";
var _53=undefined;
if(_52&&(_52!=this.stripeCount)){
_53=Math.floor((_52-this.stripeCount)/2);
var _54=(_53*this.stripeWidth);
var _55=this.getX()-_54;
this.offset+=_54;
this.updateTrackLabels(_55);
this.rawSetX(_55);
}
this.trackIterate(function(_56,_57){
_56.sizeInit(_57.stripeCount,_57.stripePercent,_53);
});
var _58=parseInt(this.scrollContainer.style.height);
_58=(_58>this.dim.height?_58:this.dim.height);
this.scrollContainer.style.height=_58+"px";
this.containerHeight=_58;
var _59=this.ref.end-this.ref.start;
var _5a=document.createElement("div");
_5a.className="overview-pos";
_5a.appendChild(document.createTextNode(Util.addCommas(this.ref.end)));
_5a.style.visibility="hidden";
this.overview.appendChild(_5a);
var _5b=_5a.clientWidth*1.2;
this.overviewPosHeight=_5a.clientHeight;
this.overview.removeChild(_5a);
for(var n=1;n<30;n++){
this.overviewStripeBases=(Math.pow(n%3,2)+1)*Math.pow(10,Math.floor(n/3));
this.overviewStripes=Math.ceil(_59/this.overviewStripeBases);
if((this.overviewBox.w/this.overviewStripes)>_5b){
break;
}
if(this.overviewStripes<2){
break;
}
}
var _5c=100/(_59/this.overviewStripeBases);
var _5d=0;
this.overviewTrackIterate(function(_5e,_5f){
_5e.clear();
_5e.sizeInit(_5f.overviewStripes,_5c);
_5e.showRange(0,_5f.overviewStripes-1,0,_5f.overviewStripeBases,_5f.overviewBox.w/(_5f.ref.end-_5f.ref.start));
});
this.updateOverviewHeight();
};
GenomeView.prototype.overviewTrackIterate=function(_60){
var _61=this.overview.firstChild;
do{
if(_61&&_61.track){
_60(_61.track,this);
}
}while(_61&&(_61=_61.nextSibling));
};
GenomeView.prototype.updateOverviewHeight=function(_62,_63){
var _64=0;
this.overviewTrackIterate(function(_65,_66){
_64+=_65.height;
});
this.overview.style.height=_64+"px";
this.overviewBox=dojo.marginBox(this.overview);
};
GenomeView.prototype.addOverviewTrack=function(_67){
var _68=this.ref.end-this.ref.start;
var _69=100/(_68/this.overviewStripeBases);
var _6a=document.createElement("div");
_6a.className="track";
_6a.style.height=this.overviewBox.h+"px";
_6a.style.left=(((-this.ref.start)/_68)*this.overviewBox.w)+"px";
_6a.id="overviewtrack_"+_67.name;
_6a.track=_67;
var _6b=this;
var _6c=function(_6d){
_6b.updateOverviewHeight();
};
_67.setViewInfo(_6c,this.overviewStripes,_6a,undefined,_69,this.overviewStripeBases,this.pxPerBp);
this.overview.appendChild(_6a);
this.updateOverviewHeight();
return _6a;
};
GenomeView.prototype.trimVertical=function(y){
if(y===undefined){
y=this.getY();
}
var _6e;
var _6f=this.topSpace;
var _70=y+this.dim.height;
for(var i=0;i<this.tracks.length;i++){
if(this.tracks[i].shown){
_6e=_6f+this.trackHeights[i];
if(!((_6e>y)&&(_6f<_70))){
this.tracks[i].hideAll();
}
_6f=_6e+this.trackPadding;
}
}
};
GenomeView.prototype.zoomIn=function(e,_71,_72){
if(this.animation){
return;
}
if(_71===undefined){
_71=0.5;
}
if(_72===undefined){
_72=1;
}
_72=Math.min(_72,(this.zoomLevels.length-1)-this.curZoom);
if(0==_72){
return;
}
this.showWait();
var pos=this.getPosition();
this.trimVertical(pos.y);
var _73=this.zoomLevels[this.curZoom+_72]/this.pxPerBp;
var _74=this.pxToBp(pos.x+this.offset+(_71*this.dim.width));
this.curZoom+=_72;
this.pxPerBp=this.zoomLevels[this.curZoom];
this.maxLeft=(this.pxPerBp*this.ref.end)-this.dim.width;
for(var _75=0;_75<this.tracks.length;_75++){
this.tracks[_75].startZoom(this.pxPerBp,_74-((_71*this.dim.width)/this.pxPerBp),_74+(((1-_71)*this.dim.width)/this.pxPerBp));
}
var _76=this;
new Zoomer(_73,this,function(){
_76.zoomUpdate(_71,_74);
},700,_71);
};
GenomeView.prototype.zoomOut=function(e,_77,_78){
if(this.animation){
return;
}
if(_78===undefined){
_78=1;
}
_78=Math.min(_78,this.curZoom);
if(0==_78){
return;
}
this.showWait();
var pos=this.getPosition();
this.trimVertical(pos.y);
if(_77===undefined){
_77=0.5;
}
var _79=this.zoomLevels[this.curZoom-_78]/this.pxPerBp;
var _7a=this.bpToPx(this.ref.end)-(this.offset+pos.x+this.dim.width);
_77=Math.max(_77,1-(((_7a*_79)/(1-_79))/this.dim.width));
_7a=pos.x+this.offset-this.bpToPx(this.ref.start);
_77=Math.min(_77,((_7a*_79)/(1-_79))/this.dim.width);
var _7b=this.pxToBp(pos.x+this.offset+(_77*this.dim.width));
this.curZoom-=_78;
this.pxPerBp=this.zoomLevels[this.curZoom];
for(var _7c=0;_7c<this.tracks.length;_7c++){
this.tracks[_7c].startZoom(this.pxPerBp,_7b-((_77*this.dim.width)/this.pxPerBp),_7b+(((1-_77)*this.dim.width)/this.pxPerBp));
}
this.minLeft=this.pxPerBp*this.ref.start;
var _7d=this;
new Zoomer(_79,this,function(){
_7d.zoomUpdate(_77,_7b);
},700,_77);
};
GenomeView.prototype.zoomUpdate=function(_7e,_7f){
var _80=this.elem.clientWidth;
var _81=this.bpToPx(_7f)-(_7e*_80)+(_80/2);
this.stripeWidth=this.stripeWidthForZoom(this.curZoom);
this.scrollContainer.style.width=(this.stripeCount*this.stripeWidth)+"px";
this.zoomContainer.style.width=(this.stripeCount*this.stripeWidth)+"px";
var _82=Math.round(_81/this.stripeWidth);
var _83=(_82-((this.stripeCount)/2))|0;
this.offset=_83*this.stripeWidth;
this.maxOffset=this.bpToPx(this.ref.end)-this.stripeCount*this.stripeWidth;
this.maxLeft=this.bpToPx(this.ref.end)-this.dim.width;
this.minLeft=this.bpToPx(this.ref.start);
this.zoomContainer.style.left="0px";
this.setX((_81-this.offset)-(_80/2));
dojo.forEach(this.uiTracks,function(_84){
_84.clear();
});
for(var _85=0;_85<this.tracks.length;_85++){
this.tracks[_85].endZoom(this.pxPerBp,Math.round(this.stripeWidth/this.pxPerBp));
}
this.showVisibleBlocks(true);
this.showDone();
this.showCoarse();
};
GenomeView.prototype.scrollUpdate=function(){
var x=this.getX();
var _86=this.stripeCount;
var _87=_86*this.stripeWidth;
var _88=this.dim.width;
var dx=(_87/2)-((_88/2)+x);
var _89=(dx/this.stripeWidth)|0;
if(0==_89){
return;
}
var _8a=Math.abs(_89);
var _8b=this.offset-(_89*this.stripeWidth);
if(this.offset==_8b){
return;
}
this.offset=_8b;
this.trackIterate(function(_8c){
_8c.moveBlocks(_89);
});
var _8d=x+(_89*this.stripeWidth);
this.updateTrackLabels(_8d);
this.rawSetX(_8d);
var _8e=(_8d/this.stripeWidth)|0;
};
GenomeView.prototype.trackHeightUpdate=function(_8f,_90){
var y=this.getY();
if(!_8f in this.trackIndices){
return;
}
var _91=this.trackIndices[_8f];
if(Math.abs(_90-this.trackHeights[_91])<1){
return;
}
if((((this.trackTops[_91]+this.trackHeights[_91])-y)<(this.dim.height/2))&&(y>0)){
this.setY(y+(_90-this.trackHeights[_91]));
}
this.trackHeights[_91]=_90;
this.tracks[_91].div.style.height=(_90+this.trackPadding)+"px";
var _92=this.trackTops[_91];
if(this.tracks[_91].shown){
_92+=_90+this.trackPadding;
}
for(var i=_91+1;i<this.tracks.length;i++){
this.trackTops[i]=_92;
this.tracks[i].div.style.top=_92+"px";
if(this.tracks[i].shown){
_92+=this.trackHeights[i]+this.trackPadding;
}
}
this.containerHeight=Math.max(_92,this.getY()+this.dim.height);
this.scrollContainer.style.height=this.containerHeight+"px";
};
GenomeView.prototype.showVisibleBlocks=function(_93,pos,_94,_95){
if(pos===undefined){
pos=this.getPosition();
}
if(_94===undefined){
_94=pos.x-(this.drawMargin*this.dim.width);
}
if(_95===undefined){
_95=pos.x+((1+this.drawMargin)*this.dim.width);
}
var _96=Math.max(0,(_94/this.stripeWidth)|0);
var _97=Math.min(this.stripeCount-1,(_95/this.stripeWidth)|0);
var _98=Math.round(this.stripeWidth/this.pxPerBp);
var _99=Math.round(this.pxToBp((_96*this.stripeWidth)+this.offset));
var _9a=Math.round(this.pxToBp(this.offset));
var _9b=Math.round(this.pxToBp(this.offset+(this.stripeCount*this.stripeWidth)));
this.trackIterate(function(_9c,_9d){
_9c.showRange(_96,_97,_99,_98,_9d.pxPerBp,_9a,_9b);
});
};
GenomeView.prototype.addTrack=function(_9e){
var _9f=this.tracks.length;
var _a0=document.createElement("div");
_a0.className="track-label dojoDndHandle";
_a0.id="label_"+_9e.name;
this.trackLabels.push(_a0);
var _a1=document.createElement("div");
_a1.className="track";
_a1.id="track_"+_9e.name;
_a1.track=_9e;
var _a2=this;
var _a3=function(_a4){
_a2.trackHeightUpdate(_9e.name,_a4);
};
_9e.setViewInfo(_a3,this.stripeCount,_a1,_a0,this.stripePercent,this.stripeWidth,this.pxPerBp);
_a0.style.position="absolute";
_a0.style.top="0px";
_a0.style.left=this.getX()+"px";
_a1.appendChild(_a0);
return _a1;
};
GenomeView.prototype.trackIterate=function(_a5){
var i;
for(i=0;i<this.uiTracks.length;i++){
_a5(this.uiTracks[i],this);
}
for(i=0;i<this.tracks.length;i++){
_a5(this.tracks[i],this);
}
};
GenomeView.prototype.updateTrackList=function(){
var _a6=[];
var _a7=this.zoomContainer.firstChild;
do{
if(_a7.track){
_a6.push(_a7.track);
}
}while((_a7=_a7.nextSibling));
this.tracks=_a6;
var _a8={};
var _a9=new Array(this.tracks.length);
for(var i=0;i<_a6.length;i++){
_a8[_a6[i].name]=i;
if(_a6[i].name in this.trackIndices){
_a9[i]=this.trackHeights[this.trackIndices[_a6[i].name]];
}else{
_a9[i]=0;
}
this.trackIndices[_a6[i].name]=i;
}
this.trackIndices=_a8;
this.trackHeights=_a9;
var _aa=this.topSpace;
for(var i=0;i<this.tracks.length;i++){
this.trackTops[i]=_aa;
this.tracks[i].div.style.top=_aa+"px";
if(this.tracks[i].shown){
_aa+=this.trackHeights[i]+this.trackPadding;
}
}
};
function ImageTrack(_1,_2,_3,_4){
Track.call(this,_1.label,_1.key,false,_4.changeCallback);
this.refSeq=_3;
this.tileToImage={};
this.zoomCache={};
this.baseUrl=(_4.baseUrl?_4.baseUrl:"");
this.load(this.baseUrl+_2);
this.imgErrorHandler=function(ev){
var _5=ev.target||ev.srcElement;
_5.style.display="none";
dojo.stopEvent(ev);
};
};
ImageTrack.prototype=new Track("");
ImageTrack.prototype.loadSuccess=function(o){
this.tileWidth=o.tileWidth;
this.zoomLevels=o.zoomLevels;
this.setLoaded();
};
ImageTrack.prototype.setViewInfo=function(_6,_7,_8,_9,_a,_b,_c){
Track.prototype.setViewInfo.apply(this,[_6,_7,_8,_9,_a,_b,_c]);
this.setLabel(this.key);
};
ImageTrack.prototype.getZoom=function(_d){
var _e=this.zoomCache[_d];
if(_e){
return _e;
}
_e=this.zoomLevels[0];
var _f=this.tileWidth/_d;
for(i=1;i<this.zoomLevels.length;i++){
if(Math.abs(this.zoomLevels[i].basesPerTile-_f)<Math.abs(_e.basesPerTile-_f)){
_e=this.zoomLevels[i];
}
}
this.zoomCache[_d]=_e;
return _e;
};
ImageTrack.prototype.getImages=function(_10,_11,_12){
var _13=(_11/_10.basesPerTile)|0;
var _14=(_12/_10.basesPerTile)|0;
_13=Math.max(_13,0);
var _15=[];
var im;
for(var i=_13;i<=_14;i++){
im=this.tileToImage[i];
if(!im){
im=document.createElement("img");
dojo.connect(im,"onerror",this.imgErrorHandler);
var _16=new RegExp("^(([^/]+:)|/)");
im.src=(_10.urlPrefix.match(_16)?"":this.baseUrl)+_10.urlPrefix+i+".png";
im.startBase=(i*_10.basesPerTile);
im.baseWidth=_10.basesPerTile;
im.tileNum=i;
this.tileToImage[i]=im;
}
_15.push(im);
}
return _15;
};
ImageTrack.prototype.fillBlock=function(_17,_18,_19,_1a,_1b,_1c,_1d,_1e,_1f,_20){
var _21=this.getZoom(_1d);
var _22=_1c-_1b;
var _23=this.getImages(_21,_1b,_1c);
var im;
for(var i=0;i<_23.length;i++){
im=_23[i];
if(!(im.parentNode&&im.parentNode.parentNode)){
im.style.position="absolute";
im.style.left=(100*((im.startBase-_1b)/_22))+"%";
im.style.width=(100*(im.baseWidth/_22))+"%";
im.style.top="0px";
im.style.height=_21.height+"px";
_18.appendChild(im);
}
}
this.heightUpdate(_21.height,_17);
};
ImageTrack.prototype.startZoom=function(_24,_25,_26){
if(this.empty){
return;
}
this.tileToImage={};
this.getImages(this.getZoom(_24),_25,_26);
};
ImageTrack.prototype.endZoom=function(_27,_28){
Track.prototype.clear.apply(this);
};
ImageTrack.prototype.clear=function(){
Track.prototype.clear.apply(this);
this.tileToImage={};
};
ImageTrack.prototype.transfer=function(_29,_2a,_2b,_2c,_2d){
if(!(_29&&_2a)){
return;
}
var _2e=_29.childNodes;
var _2f=_2a.startBase;
var _30=_2a.endBase;
var im;
for(var i=0;i<_2e.length;i++){
im=_2e[i];
if("startBase" in im){
if((im.startBase<_30)&&((im.startBase+im.baseWidth)>_2f)){
im.style.left=(100*((im.startBase-_2f)/(_30-_2f)))+"%";
_2a.appendChild(im);
}else{
delete this.tileToImage[im.tileNum];
}
}
}
};
function Contour(_1){
if(_1===undefined){
_1=0;
}
this.spans=[{top:_1,x:Infinity,height:0}];
};
Contour.prototype.getFit=function(x,_2,_3){
var _4,_5;
var _6=0;
if(_3){
for(;this.spans[_6].top<_3;_6++){
if(_6>=(this.spans.length-1)){
return {above:this.spans.length-1,count:0};
}
}
}
ABOVE:
for(;_6<this.spans.length;_6++){
_4=this.spans[_6].top+this.spans[_6].height;
for(var _7=1;_6+_7<this.spans.length;_7++){
_5=this.spans[_6+_7];
if((_4+_2)<=_5.top){
return {above:_6,count:_7-1};
}
if(_5.x>x){
continue ABOVE;
}
if((_5.x<=x)&&((_4+_2)<(_5.top+_5.height))){
return {above:_6,count:_7-1};
}
}
return {above:_6,count:_7-1};
}
return {above:_6,count:0};
};
Contour.prototype.insertFit=function(_8,x,_9,_a){
var _b=this.spans[_8.above];
if((Math.abs(_b.x-x)<1)&&(Math.abs((_b.top+_b.height)-_9)<1)){
_b.height=(_9+_a)-_b.top;
_b.x=Math.max(_b.x,x);
this.spans.splice(_8.above+1,_8.count);
}else{
this.spans.splice(_8.above+1,_8.count,{top:_9,x:x,height:_a});
}
};
Contour.prototype.unionWith=function(x,_c,_d){
var _e,_f,_10,_11,_12;
var _13=_c+_d;
START:
for(_f=0;_f<this.spans.length;_f++){
_11=this.spans[_f];
_e=_11.top+_11.height;
if(_11.top>_c){
_10=_f;
break START;
}
if(_e>_c){
if(_11.x>=x){
var _14=_e-_c;
_c+=_14;
_d-=_14;
if(_c>=_13){
return;
}
continue;
}else{
for(_10=_f;_10<this.spans.length;_10++){
_12=this.spans[_10];
if(((_12.top+_12.height)>_13)||_12.x>x){
break START;
}
}
break START;
}
}
}
var _15=this.spans[_f-1];
if((Math.abs(_15.x-x)<1)&&(Math.abs((_15.top+_15.height)-_c)<1)){
_15.height=(_c+_d)-_15.top;
_15.x=Math.max(_15.x,x);
this.spans.splice(_f,_10-_f);
}else{
this.spans.splice(_f,_10-_f,{top:_c,x:x,height:_d});
}
};
Contour.prototype.getNextTop=function(fit){
return this.spans[fit.above].top+this.spans[fit.above].height;
};
function Layout(_16,_17){
this.leftBound=_16;
this.rightBound=_17;
this.leftContour=new Contour();
this.rightContour=new Contour();
this.seen={};
this.leftOverlaps=[];
this.rightOverlaps=[];
this.totalHeight=0;
};
Layout.prototype.addRect=function(id,_18,_19,_1a){
if(this.seen[id]!==undefined){
return this.seen[id];
}
var _1b=this.tryLeftFit(_18,_19,_1a,0);
var _1c=this.tryRightFit(_18,_19,_1a,0);
var top;
if(_1b.top<_1c.top){
top=_1b.top;
this.leftContour.insertFit(_1b.fit,this.rightBound-_18,top,_1a);
this.rightContour.unionWith(_19-this.leftBound,top,_1a);
}else{
top=_1c.top;
this.rightContour.insertFit(_1c.fit,_19-this.leftBound,top,_1a);
this.leftContour.unionWith(this.rightBound-_18,top,_1a);
}
var _1d={id:id,left:_18,right:_19,top:top,height:_1a};
this.seen[id]=top;
if(_18<=this.leftBound){
this.leftOverlaps.push(_1d);
if(this.leftLayout){
this.leftLayout.addExisting(_1d);
}
}
if(_19>=this.rightBound){
this.rightOverlaps.push(_1d);
if(this.rightLayout){
this.rightLayout.addExisting(_1d);
}
}
this.seen[id]=top;
this.totalHeight=Math.max(this.totalHeight,top+_1a);
return top;
};
Layout.prototype.tryLeftFit=function(_1e,_1f,_20,top){
var fit,_21;
var _22=top;
while(true){
fit=this.leftContour.getFit(this.rightBound-_1f,_20,_22);
_22=Math.max(this.leftContour.getNextTop(fit),_22);
if(this.rightLayout&&(_1f>=this.rightBound)){
_21=this.rightLayout.tryLeftFit(_1e,_1f,_20,_22);
if(_21.top>_22){
_22=_21.top;
continue;
}
}
break;
}
return {top:_22,fit:fit};
};
Layout.prototype.tryRightFit=function(_23,_24,_25,top){
var fit,_26;
var _27=top;
while(true){
fit=this.rightContour.getFit(_23-this.leftBound,_25,_27);
_27=Math.max(this.rightContour.getNextTop(fit),_27);
if(this.leftLayout&&(_23<=this.leftBound)){
_26=this.leftLayout.tryRightFit(_23,_24,_25,_27);
if(_26.top>_27){
_27=_26.top;
continue;
}
}
break;
}
return {top:_27,fit:fit};
};
Layout.prototype.hasSeen=function(id){
return (this.seen[id]!==undefined);
};
Layout.prototype.setLeftLayout=function(_28){
for(var i=0;i<this.leftOverlaps.length;i++){
_28.addExisting(this.leftOverlaps[i]);
}
this.leftLayout=_28;
};
Layout.prototype.setRightLayout=function(_29){
for(var i=0;i<this.rightOverlaps.length;i++){
_29.addExisting(this.rightOverlaps[i]);
}
this.rightLayout=_29;
};
Layout.prototype.cleanup=function(){
this.leftLayout=undefined;
this.rightLayout=undefined;
};
Layout.prototype.addExisting=function(_2a){
if(this.seen[_2a.id]!==undefined){
return;
}
this.seen[_2a.id]=_2a.top;
this.totalHeight=Math.max(this.totalHeight,_2a.top+_2a.height);
if(_2a.left<=this.leftBound){
this.leftOverlaps.push(_2a);
if(this.leftLayout){
this.leftLayout.addExisting(_2a);
}
}
if(_2a.right>=this.rightBound){
this.rightOverlaps.push(_2a);
if(this.rightLayout){
this.rightLayout.addExisting(_2a);
}
}
this.leftContour.unionWith(this.rightBound-_2a.left,_2a.top,_2a.height);
this.rightContour.unionWith(_2a.right-this.leftBound,_2a.top,_2a.height);
};
function LazyArray(_1,_2){
this.urlTemplate=_1.urlTemplate;
this.chunkSize=_1.chunkSize;
this.length=_1.length;
this.baseUrl=(_2===undefined?"":_2);
this.chunks=[];
this.toProcess={};
};
LazyArray.prototype.index=function(i,_3,_4){
this.range(i,i,_3,undefined,_4);
};
LazyArray.prototype.range=function(_5,_6,_7,_8,_9){
_5=Math.max(0,_5);
_6=Math.min(_6,this.length-1);
var _a=Math.floor(_5/this.chunkSize);
var _b=Math.floor(_6/this.chunkSize);
if(_8===undefined){
_8=function(){
};
}
var _c=new Finisher(_8);
for(var _d=_a;_d<=_b;_d++){
if(this.chunks[_d]){
this._processChunk(_5,_6,_d,_7,_9);
}else{
var _e={start:_5,end:_6,callback:_7,param:_9,finish:_c};
_c.inc();
if(this.toProcess[_d]){
this.toProcess[_d].push(_e);
}else{
this.toProcess[_d]=[_e];
var _f=this.urlTemplate.replace(/\{chunk\}/g,_d);
var _10=this;
dojo.xhrGet({url:this.baseUrl+_f,handleAs:"json",load:this._makeLoadFun(_d),error:function(){
_c.dec();
}});
}
}
}
_c.finish();
};
LazyArray.prototype._makeLoadFun=function(_11){
var _12=this;
return function(_13){
_12.chunks[_11]=_13;
var _14=_12.toProcess[_11];
delete _12.toProcess[_11];
for(var i=0;i<_14.length;i++){
_12._processChunk(_14[i].start,_14[i].end,_11,_14[i].callback,_14[i].param);
_14[i].finish.dec();
}
};
};
LazyArray.prototype._processChunk=function(_15,end,_16,_17,_18){
var _19=_16*this.chunkSize;
var _1a=_15-_19;
var _1b=end-_19;
_1a=Math.max(0,_1a);
_1b=Math.min(_1b,this.chunkSize-1);
for(var i=_1a;i<=_1b;i++){
_17(i+_19,this.chunks[_16][i],_18);
}
};
function LazyTrie(_1,_2){
this.baseURL=_1;
var _3=this;
dojo.xhrGet({url:_2,handleAs:"json",load:function(o){
if(!o){
//console.log("failed to load trie");
return;
}
_3.root=o;
_3.extra=o[0];
if(_3.deferred){
_3.deferred.callee.apply(_3,_3.deferred);
delete _3.deferred;
}
}});
};
LazyTrie.prototype.pathToPrefix=function(_4){
var _5=this.root;
var _6="";
loop:
for(var i=0;i<_4.length;i++){
switch(typeof _5[_4[i]][0]){
case "string":
_6+=_5[_4[i]][0];
break;
case "number":
_6+=_5[_4[i]][1];
break loop;
}
_5=_5[_4[i]];
}
return _6;
};
LazyTrie.prototype.valuesFromPrefix=function(_7,_8){
var _9=this;
this.findNode(_7,function(_a,_b){
_8(_9.valuesFromNode(_b));
});
};
LazyTrie.prototype.mappingsFromPrefix=function(_c,_d){
var _e=this;
this.findNode(_c,function(_f,_10){
_d(_e.mappingsFromNode(_f,_10));
});
};
LazyTrie.prototype.mappingsFromNode=function(_11,_12){
var _13=[];
if(_12[1]!==null){
_13.push([_11,_12[1]]);
}
for(var i=2;i<_12.length;i++){
if("string"==typeof _12[i][0]){
_13=_13.concat(this.mappingsFromNode(_11+_12[i][0],_12[i]));
}
}
return _13;
};
LazyTrie.prototype.valuesFromNode=function(_14){
var _15=[];
if(_14[1]!==null){
_15.push(_14[1]);
}
for(var i=2;i<_14.length;i++){
_15=_15.concat(this.valuesFromNode(_14[i]));
}
return _15;
};
LazyTrie.prototype.exactMatch=function(key,_16){
var _17=this;
this.findNode(key,function(_18,_19){
if((_18.toLowerCase()==key.toLowerCase())&&_19[1]){
_16(_19[1]);
}
});
};
LazyTrie.prototype.findNode=function(_1a,_1b){
var _1c=this;
this.findPath(_1a,function(_1d){
var _1e=_1c.root;
for(i=0;i<_1d.length;i++){
_1e=_1e[_1d[i]];
}
var _1f=_1c.pathToPrefix(_1d);
_1b(_1f,_1e);
});
};
LazyTrie.prototype.findPath=function(_20,_21){
if(!this.root){
this.deferred=arguments;
return;
}
_20=_20.toLowerCase();
var _22=this.root;
var _23=0;
var _24;
var _25=[];
while(true){
_24=this.binarySearch(_22,_20.charAt(_23));
if(_24<0){
return;
}
_25.push(_24);
if("number"==typeof _22[_24][0]){
var _26=this;
dojo.xhrGet({url:this.baseURL+this.pathToPrefix(_25)+".json",handleAs:"json",load:function(o){
_22[_24]=o;
_26.findPath(_20,_21);
}});
return;
}
_22=_22[_24];
if(_20.substr(_23,_22[0].length)!=_22[0].substr(0,Math.min(_22[0].length,_20.length-_23))){
return;
}
_23+=_22[0].length;
if(_23>=_20.length){
_21(_25);
return;
}
}
};
LazyTrie.prototype.binarySearch=function(a,_27){
var low=2;
var _28=a.length-1;
var mid,_29;
while(low<=_28){
mid=(low+_28)>>>1;
switch(typeof a[mid][0]){
case "string":
_29=a[mid][0].charAt(0);
break;
case "number":
_29=a[mid][1].charAt(0);
break;
}
if(_29<_27){
low=mid+1;
}else{
if(_29>_27){
_28=mid-1;
}else{
return mid;
}
}
}
return -(low+1);
};
function NCList(){
};
NCList.prototype.importExisting=function(_1,_2,_3,_4,_5){
this.topList=_1;
this.sublistIndex=_2;
this.lazyIndex=_3;
this.baseURL=_4;
this.lazyUrlTemplate=_5;
};
NCList.prototype.fill=function(_6,_7){
this.sublistIndex=_7;
var _8=_6;
_8.sort(function(a,b){
if(a[0]!=b[0]){
return a[0]-b[0];
}else{
return b[1]-a[1];
}
});
var _9=new Array();
var _a=new Array();
this.topList=_a;
_a.push(_8[0]);
var _b,_c;
for(var i=1,_d=_8.length;i<_d;i++){
_b=_8[i];
if(_b[1]<_8[i-1][1]){
_9.push(_a);
_a=new Array(_b);
_8[i-1][_7]=_a;
}else{
while(true){
if(0==_9.length){
_a.push(_b);
break;
}else{
_c=_9[_9.length-1];
if(_c[_c.length-1][1]>_b[1]){
_a.push(_b);
break;
}else{
_a=_9.pop();
}
}
}
}
}
};
NCList.prototype.binarySearch=function(_e,_f,_10){
var low=-1;
var _11=_e.length;
var mid;
while(_11-low>1){
mid=(low+_11)>>>1;
if(_e[mid][_10]>_f){
_11=mid;
}else{
low=mid;
}
}
if(1==_10){
return _11;
}else{
return low;
}
};
NCList.prototype.iterHelper=function(arr,_12,to,fun,_13,inc,_14,_15,_16){
var len=arr.length;
var i=this.binarySearch(arr,_12,_14);
while((i<len)&&(i>=0)&&((inc*arr[i][_15])<(inc*to))){
if("object"==typeof arr[i][this.lazyIndex]){
var ncl=this;
if(arr[i][this.lazyIndex].state){
if("loading"==arr[i][this.lazyIndex].state){
_13.inc();
arr[i][this.lazyIndex].callbacks.push(function(_17){
return function(o){
ncl.iterHelper(o,_12,to,fun,_13,inc,_14,_15,_16.concat(_17));
_13.dec();
};
}(i));
}else{
if("loaded"==arr[i][this.lazyIndex].state){
}else{
//console.log("unknown lazy type: "+arr[i]);
}
}
}else{
arr[i][this.lazyIndex].state="loading";
arr[i][this.lazyIndex].callbacks=[];
_13.inc();
dojo.xhrGet({url:this.baseURL+this.lazyUrlTemplate.replace(/\{chunk\}/g,arr[i][this.lazyIndex].chunk),handleAs:"json",load:function(_18,_19,_1a,_1b){
return function(o){
_19.state="loaded";
_18[_1a]=o;
ncl.iterHelper(o,_12,to,fun,_13,inc,_14,_15,_16.concat(_1b));
for(var c=0;c<_19.callbacks.length;c++){
_19.callbacks[c](o);
}
_13.dec();
};
}(arr[i],arr[i][this.lazyIndex],this.sublistIndex,i),error:function(){
_13.dec();
}});
}
}else{
fun(arr[i],_16.concat(i));
}
if(arr[i][this.sublistIndex]){
this.iterHelper(arr[i][this.sublistIndex],_12,to,fun,_13,inc,_14,_15,_16.concat(i));
}
i+=inc;
}
};
NCList.prototype.iterate=function(_1c,to,fun,_1d){
var inc=(_1c>to)?-1:1;
var _1e=(_1c>to)?0:1;
var _1f=(_1c>to)?1:0;
var _20=new Finisher(_1d);
this.iterHelper(this.topList,_1c,to,fun,_20,inc,_1e,_1f,[]);
_20.finish();
};
NCList.prototype.histogram=function(_21,to,_22,_23){
var _24=new Array(_22);
var _25=(to-_21)/_22;
for(var i=0;i<_22;i++){
_24[i]=0;
}
this.iterate(_21,to,function(_26){
var _27=Math.max(0,((_26[0]-_21)/_25)|0);
var _28=Math.min(_22,((_26[1]-_21)/_25)|0);
for(var bin=_27;bin<=_28;bin++){
_24[bin]++;
}
},function(){
_23(_24);
});
};
function SequenceTrack(_1,_2,_3,_4){
Track.call(this,_1.label,_1.key,false,_4.changeCallback);
this.browserParams=_4;
this.trackMeta=_1;
this.setLoaded();
this.chunks=[];
this.chunkSize=_1.args.chunkSize;
this.baseUrl=(_4.baseUrl?_4.baseUrl:"")+_2;
};
SequenceTrack.prototype=new Track("");
SequenceTrack.prototype.startZoom=function(_5,_6,_7){
this.hide();
this.heightUpdate(0);
};
SequenceTrack.prototype.endZoom=function(_8,_9){
if(_8==this.browserParams.charWidth){
this.show();
}
Track.prototype.clear.apply(this);
};
SequenceTrack.prototype.setViewInfo=function(_a,_b,_c,_d,_e,_f,_10){
Track.prototype.setViewInfo.apply(this,[_a,_b,_c,_d,_e,_f,_10]);
if(_10==this.browserParams.charWidth){
this.show();
}else{
this.hide();
}
this.setLabel(this.key);
};
SequenceTrack.prototype.fillBlock=function(_11,_12,_13,_14,_15,_16,_17,_18,_19,_1a){
if(this.shown){
this.getRange(_15,_16,function(_1b,end,seq){
var _1c=document.createElement("div");
_1c.className="sequence";
_1c.appendChild(document.createTextNode(seq));
_1c.style.cssText="top: 0px;";
_12.appendChild(_1c);
});
this.heightUpdate(this.browserParams.seqHeight,_11);
}else{
this.heightUpdate(0,_11);
}
};
SequenceTrack.prototype.getRange=function(_1d,end,_1e){
var _1f=Math.floor((_1d)/this.chunkSize);
var _20=Math.floor((end-1)/this.chunkSize);
var _21={start:_1d,end:end,callback:_1e};
var _22=this.chunkSize;
var _23;
for(var i=_1f;i<=_20;i++){
_23=this.chunks[i];
if(_23){
if(_23.loaded){
_1e(_1d,end,_23.sequence.substring(_1d-(i*_22),end-(i*_22)));
}else{
_23.callbacks.push(_21);
}
}else{
_23={loaded:false,num:i,callbacks:[_21]};
this.chunks[i]=_23;
dojo.xhrGet({url:this.baseUrl+i+".txt",load:function(_24){
var ci;
_23.sequence=_24;
for(var c=0;c<_23.callbacks.length;c++){
ci=_23.callbacks[c];
ci.callback(ci.start,ci.end,_24.substring(ci.start-(_23.num*_22),ci.end-(_23.num*_22)));
}
_23.callbacks=undefined;
_23.loaded=true;
}});
}
}
};
function CompareObjPos(_1,_2){
var _3=0,j=0,_4=_2.pageY;
for(var i=0;i<_1.length;i++){
_3=j++;
var _5=findPos(_1[i]);
if(_5.top>_4){
break;
}
}
return _3;
};
function checkAvatarPosition(_6){
var _7=document.getElementById("tracksAvail"),_8=document.getElementById("container");
if(_6.pageX<(_7.offsetLeft+_7.offsetWidth)){
return _7;
}else{
return _8;
}
};
var startX;
function removeTouchEvents(){
startX=null;
};
function touchSimulated(_9){
if(_9.touches.length<=1){
var _a=_9.changedTouches,_b=_a[0],_c="",_d="mouseover",_e=document.getElementsByClassName("dojoDndAvatar"),_f={},_10=checkAvatarPosition(_b),_11=_10.getElementsByClassName("dojoDndItem"),_12={},_13=document.createEvent("MouseEvent"),_14=document.createEvent("MouseEvent");
switch(_9.type){
case "touchstart":
startX=_b.pageX;
_c="mousedown";
break;
case "touchmove":
_9.preventDefault();
_c="mousemove";
break;
default:
return;
}
_13.initMouseEvent(_c,true,true,window,1,_b.pageX,_b.pageY,_b.clientX,_b.clientY,false,false,false,false,0,null);
_14.initMouseEvent(_d,true,true,window,1,_b.pageX,_b.pageY,_b.clientX,_b.clientY,false,false,false,false,0,null);
switch(_9.type){
case "touchstart":
_b.target.dispatchEvent(_13);
_b.target.dispatchEvent(_14);
initialPane=_10;
break;
case "touchmove":
if(_e.length>0){
if(_11.length>0){
_12=CompareObjPos(_11,_b);
_f=_11[_12];
}
try{
if(initialPane!=_10){
var _15=document.createEvent("MouseEvent");
var _16="mouseout";
_15.initMouseEvent(_16,true,true,window,1,_b.pageX,_b.pageY,_b.clientX,_b.clientY,false,false,false,false,0,null);
initialPane.dispatchEvent(_15);
}
_f.dispatchEvent(_14);
_f.dispatchEvent(_13);
}
catch(err){
_10.dispatchEvent(_14);
_10.dispatchEvent(_13);
}
}
break;
default:
return;
}
}else{
removeTouchEvents();
}
};
function touchEnd(_17){
var _18=_17.changedTouches,_19=_18[0],_1a="mouseup",_1b="mouseover",_1c=document.getElementsByClassName("dojoDndAvatar"),obj={},_1d=checkAvatarPosition(_19),_1e=_1d.getElementsByClassName("dojoDndItem"),_1f={},_20=document.createEvent("MouseEvent"),_21=document.createEvent("MouseEvent");
if(startX!==_19.pageX){
_17.preventDefault();
}
var _22=findPos(_19.target);
_20.initMouseEvent(_1a,true,true,window,1,_19.pageX,_19.pageY,_19.clientX,_19.clientY,false,false,false,false,0,null);
_21.initMouseEvent(_1b,true,true,window,1,_19.pageX,_19.pageY,_19.clientX,_19.clientY,false,false,false,false,0,null);
if(_1c.length>0){
if(_1e.length>0){
_1f=CompareObjPos(_1e,_19);
obj=_1e[_1f];
}
try{
obj.dispatchEvent(_21);
obj.dispatchEvent(_20);
}
catch(error){
_19.target.dispatchEvent(_21);
_1d.dispatchEvent(_21);
}
}else{
_19.target.dispatchEvent(_20);
_19.target.dispatchEvent(_21);
}
removeTouchEvents();
};
function touchHandle(_23){
dojo.query(".dojoDndItemAnchor").connect("touchstart",touchSimulated);
dojo.query(".dojoDndItemAnchor").connect("touchmove",touchSimulated);
dojo.query(".dojoDndItemAnchor").connect("touchend",touchEnd);
dojo.query(".dojoDndItemAnchor").connect("click",function(){
void (0);
});
if(_23.touches.length<=1){
var _24=_23.changedTouches,_25=_24[0],_26="";
switch(_23.type){
case "touchstart":
startX=_25.pageX;
_26="mousedown";
break;
case "touchmove":
_23.preventDefault();
_26="mousemove";
break;
case "touchend":
if(startX!==_25.pageX){
_23.preventDefault();
}
_26="mouseup";
break;
default:
return;
}
var _27=document.createEvent("MouseEvent");
_27.initMouseEvent(_26,true,true,window,1,_25.screenX,_25.screenY,_25.clientX,_25.clientY,false,false,false,false,0,null);
_25.target.dispatchEvent(_27);
}else{
removeTouchEvents();
}
};
function touchinit(){
dojo.query(".dojoDndItem").connect("touchstart",touchSimulated);
dojo.query(".dojoDndItem").connect("touchmove",touchSimulated);
dojo.query(".dojoDndItem").connect("touchend",touchEnd);
dojo.query(".locationThumb").connect("touchstart",touchHandle);
dojo.query(".locationThumb").connect("touchmove",touchHandle);
dojo.query(".locationThumb").connect("touchend",touchHandle);
dojo.query(".dojoDndItem").connect("click",function(){
void (0);
});
dojo.query(".dojoDndTarget").connect("touchstart",touchHandle);
dojo.query(".dojoDndTarget").connect("touchmove",touchHandle);
dojo.query(".dojoDndTarget").connect("touchend",touchHandle);
dojo.query(".dijitSplitter").connect("touchstart",touchHandle);
dojo.query(".dijitSplitter").connect("touchmove",touchHandle);
dojo.query(".dijitSplitter").connect("touchend",touchHandle);
};
function load(){
touchinit();
document.documentElement.style.webkitTouchCallout="none";
};
function findPos(obj){
var _28=0,_29={};
if(obj.offsetParent){
do{
_28+=obj.offsetTop;
}while((obj=obj.offsetParent));
}
_29.top=_28;
return _29;
};
function Track(_1,_2,_3,_4){
this.name=_1;
this.key=_2;
this.loaded=_3;
this.changed=_4;
this.height=0;
this.shown=true;
this.empty=false;
};
Track.prototype.load=function(_5){
var _6=this;
dojo.xhrGet({url:_5,handleAs:"json",load:function(o){
_6.loadSuccess(o);
},error:function(o){
_6.loadFail(o);
}});
};
Track.prototype.loadFail=function(_7){
this.empty=true;
this.setLoaded();
};
Track.prototype.setViewInfo=function(_8,_9,_a,_b,_c,_d,_e){
var _f=this;
this.heightUpdate=function(_10,_11){
if(!this.shown){
_8(0);
return;
}
if(_11!==undefined){
_f.blockHeights[_11]=_10;
}
_f.height=Math.max(_f.height,_10);
if(!_f.inShowRange){
_8(Math.max(_f.labelHeight,_f.height));
}
};
this.div=_a;
this.label=_b;
this.widthPct=_c;
this.widthPx=_d;
this.leftBlank=document.createElement("div");
this.leftBlank.className="blank-block";
this.rightBlank=document.createElement("div");
this.rightBlank.className="blank-block";
this.div.appendChild(this.rightBlank);
this.div.appendChild(this.leftBlank);
this.sizeInit(_9,_c);
this.labelHTML="";
this.labelHeight=0;
};
Track.prototype.hide=function(){
if(this.shown){
this.div.style.display="none";
this.shown=false;
}
};
Track.prototype.show=function(){
if(!this.shown){
this.div.style.display="block";
this.shown=true;
}
};
Track.prototype.initBlocks=function(){
this.blocks=new Array(this.numBlocks);
this.blockHeights=new Array(this.numBlocks);
for(var i=0;i<this.numBlocks;i++){
this.blockHeights[i]=0;
}
this.firstAttached=null;
this.lastAttached=null;
this._adjustBlanks();
};
Track.prototype.clear=function(){
if(this.blocks){
for(var i=0;i<this.numBlocks;i++){
this._hideBlock(i);
}
}
this.initBlocks();
};
Track.prototype.setLabel=function(_12){
if(this.label===undefined){
return;
}
if(this.labelHTML==_12){
return;
}
this.labelHTML=_12;
this.label.innerHTML=_12;
this.labelHeight=this.label.offsetHeight;
};
Track.prototype.transfer=function(){
};
Track.prototype.startZoom=function(_13,_14,_15){
};
Track.prototype.endZoom=function(_16,_17){
};
Track.prototype.showRange=function(_18,_19,_1a,_1b,_1c,_1d,_1e){
if(this.blocks===undefined){
return 0;
}
if((this.labelHeight==0)&&this.label){
this.labelHeight=this.label.offsetHeight;
}
this.inShowRange=true;
this.height=this.labelHeight;
var _1f=(null==this.firstAttached?_19+1:this.firstAttached);
var _20=(null==this.lastAttached?_18-1:this.lastAttached);
var i,_21;
var _22=0;
for(i=_20;i>=_18;i--){
_21=_1a+(_1b*(i-_18));
this._showBlock(i,_21,_21+_1b,_1c,_1d,_1e);
}
for(i=_20+1;i<=_19;i++){
_21=_1a+(_1b*(i-_18));
this._showBlock(i,_21,_21+_1b,_1c,_1d,_1e);
}
var _23=this.blocks[_18];
for(i=_1f;i<_18;i++){
this.transfer(this.blocks[i],_23,_1c,_1d,_1e);
this.cleanupBlock(this.blocks[i]);
this._hideBlock(i);
}
_23=this.blocks[_19];
for(i=_20;i>_19;i--){
this.transfer(this.blocks[i],_23,_1c,_1d,_1e);
this.cleanupBlock(this.blocks[i]);
this._hideBlock(i);
}
this.firstAttached=_18;
this.lastAttached=_19;
this._adjustBlanks();
this.inShowRange=false;
this.heightUpdate(this.height);
};
Track.prototype.cleanupBlock=function(){
};
Track.prototype._hideBlock=function(_24){
if(this.blocks[_24]){
this.div.removeChild(this.blocks[_24]);
this.blocks[_24]=undefined;
this.blockHeights[_24]=0;
}
};
Track.prototype._adjustBlanks=function(){
if((this.firstAttached===null)||(this.lastAttached===null)){
this.leftBlank.style.left="0px";
this.leftBlank.style.width="50%";
this.rightBlank.style.left="50%";
this.rightBlank.style.width="50%";
}else{
this.leftBlank.style.width=(this.firstAttached*this.widthPct)+"%";
this.rightBlank.style.left=((this.lastAttached+1)*this.widthPct)+"%";
this.rightBlank.style.width=((this.numBlocks-this.lastAttached-1)*this.widthPct)+"%";
}
};
Track.prototype.hideAll=function(){
if(null==this.firstAttached){
return;
}
for(var i=this.firstAttached;i<=this.lastAttached;i++){
this._hideBlock(i);
}
this.firstAttached=null;
this.lastAttached=null;
this._adjustBlanks();
};
Track.prototype.setLoaded=function(){
this.loaded=true;
this.hideAll();
this.changed();
};
Track.prototype._loadingBlock=function(_25){
_25.appendChild(document.createTextNode("Loading..."));
_25.style.backgroundColor="#eee";
return 50;
};
Track.prototype._showBlock=function(_26,_27,_28,_29,_2a,_2b){
if(this.blocks[_26]){
this.heightUpdate(this.blockHeights[_26],_26);
return;
}
if(this.empty){
this.heightUpdate(this.labelHeight,_26);
return;
}
var _2c=document.createElement("div");
_2c.className="block";
_2c.style.left=(_26*this.widthPct)+"%";
_2c.style.width=this.widthPct+"%";
_2c.startBase=_27;
_2c.endBase=_28;
if(this.loaded){
this.fillBlock(_26,_2c,this.blocks[_26-1],this.blocks[_26+1],_27,_28,_29,this.widthPx,_2a,_2b);
}else{
this._loadingBlock(_2c);
}
this.blocks[_26]=_2c;
this.div.appendChild(_2c);
};
Track.prototype.moveBlocks=function(_2d){
var _2e=new Array(this.numBlocks);
var _2f=new Array(this.numBlocks);
var i;
for(i=0;i<this.numBlocks;i++){
_2f[i]=0;
}
var _30;
if((this.lastAttached+_2d<0)||(this.firstAttached+_2d>=this.numBlocks)){
this.firstAttached=null;
this.lastAttached=null;
}else{
this.firstAttached=Math.max(0,Math.min(this.numBlocks-1,this.firstAttached+_2d));
this.lastAttached=Math.max(0,Math.min(this.numBlocks-1,this.lastAttached+_2d));
if(_2d<0){
_30=this.blocks[this.firstAttached-_2d];
}else{
_30=this.blocks[this.lastAttached-_2d];
}
}
for(i=0;i<this.blocks.length;i++){
var _31=i+_2d;
if((_31<0)||(_31>=this.numBlocks)){
if(_30&&this.blocks[i]){
this.transfer(this.blocks[i],_30);
}
this._hideBlock(i);
}else{
_2e[_31]=this.blocks[i];
if(_2e[_31]){
_2e[_31].style.left=((_31)*this.widthPct)+"%";
}
_2f[_31]=this.blockHeights[i];
}
}
this.blocks=_2e;
this.blockHeights=_2f;
this._adjustBlanks();
};
Track.prototype.sizeInit=function(_32,_33,_34){
var i,_35;
this.numBlocks=_32;
this.widthPct=_33;
if(_34){
this.moveBlocks(-_34);
}
if(this.blocks&&(this.blocks.length>0)){
var _36=this.blocks[_32-1];
for(i=_32;i<this.blocks.length;i++){
if(_36&&this.blocks[i]){
this.transfer(this.blocks[i],_36);
}
this._hideBlock(i);
}
_35=this.blocks.length;
this.blocks.length=_32;
this.blockHeights.length=_32;
for(i=_35;i<_32;i++){
this.blocks[i]=undefined;
this.blockHeights[i]=0;
}
this.lastAttached=Math.min(this.lastAttached,_32-1);
if(this.firstAttached>this.lastAttached){
this.firstAttached=null;
this.lastAttached=null;
}
if(this.blocks.length!=_32){
throw new Error("block number mismatch: should be "+_32+"; blocks.length: "+this.blocks.length);
}
for(i=0;i<_32;i++){
if(this.blocks[i]){
this.blocks[i].style.left=(i*_33)+"%";
this.blocks[i].style.width=_33+"%";
}
}
}else{
this.initBlocks();
}
};
function StaticTrack(_1,_2,_3){
Track.call(this,_1,_1,true,function(){
});
this.labelClass=_2;
this.posHeight=_3;
this.height=_3;
};
StaticTrack.prototype=new Track("");
StaticTrack.prototype.fillBlock=function(_4,_5,_6,_7,_8,_9,_a,_b,_c){
var _d=document.createElement("div");
_d.className=this.labelClass;
_d.appendChild(document.createTextNode(Util.addCommas(_8)));
_d.style.top="0px";
_5.appendChild(_d);
this.heightUpdate(this.posHeight,_4);
};
function GridTrack(_e){
Track.call(this,_e,_e,true,function(){
});
};
GridTrack.prototype=new Track("");
GridTrack.prototype.fillBlock=function(_f,_10,_11,_12,_13,_14,_15,_16,_17){
var _18=document.createElement("div");
_18.className="gridline";
_18.style.cssText="left: 0%; width: 0px;";
_10.appendChild(_18);
this.heightUpdate(100,_f);
};
var Util={};
Util.is_ie=navigator.appVersion.indexOf("MSIE")>=0;
Util.is_ie6=navigator.appVersion.indexOf("MSIE 6")>=0;
Util.addCommas=function(_1){
_1+="";
x=_1.split(".");
x1=x[0];
x2=x.length>1?"."+x[1]:"";
var _2=/(\d+)(\d{3})/;
while(_2.test(x1)){
x1=x1.replace(_2,"$1"+","+"$2");
}
return x1+x2;
};
Util.wheel=function(_3){
var _4=0;
if(!_3){
_3=window.event;
}
if(_3.wheelDelta){
_4=_3.wheelDelta/120;
if(window.opera){
_4=-_4;
}
}else{
if(_3.detail){
_4=-_3.detail/3;
}
}
return Math.round(_4);
};
Util.isRightButton=function(e){
if(!e){
var e=window.event;
}
if(e.which){
return e.which==3;
}else{
if(e.button){
return e.button==2;
}
}
};
Util.getViewportWidth=function(){
var _5=0;
if(document.documentElement&&document.documentElement.clientWidth){
_5=document.documentElement.clientWidth;
}else{
if(document.body&&document.body.clientWidth){
_5=document.body.clientWidth;
}else{
if(window.innerWidth){
_5=window.innerWidth-18;
}
}
}
return _5;
};
Util.getViewportHeight=function(){
var _6=0;
if(document.documentElement&&document.documentElement.clientHeight){
_6=document.documentElement.clientHeight;
}else{
if(document.body&&document.body.clientHeight){
_6=document.body.clientHeight;
}else{
if(window.innerHeight){
_6=window.innerHeight-18;
}
}
}
return _6;
};
Util.findNearest=function(_7,_8){
var _9=0;
var _a=Math.abs(_8-_7[0]);
for(var i=0;i<_7.length;i++){
if(Math.abs(_8-_7[i])<_a){
_9=i;
_a=Math.abs(_8-_7[i]);
}
}
return _9;
};
if(!Array.prototype.reduce){
Array.prototype.reduce=function(_b){
var _c=this.length;
if(typeof _b!="function"){
throw new TypeError();
}
if(_c==0&&arguments.length==1){
throw new TypeError();
}
var i=0;
if(arguments.length>=2){
var rv=arguments[1];
}else{
do{
if(i in this){
rv=this[i++];
break;
}
if(++i>=_c){
throw new TypeError();
}
}while(true);
}
for(;i<_c;i++){
if(i in this){
rv=_b.call(null,rv,this[i],i,this);
}
}
return rv;
};
}
function Finisher(_d){
this.fun=_d;
this.count=0;
};
Finisher.prototype.inc=function(){
this.count++;
};
Finisher.prototype.dec=function(){
this.count--;
this.finish();
};
Finisher.prototype.finish=function(){
if(this.count<=0){
this.fun();
}
};

