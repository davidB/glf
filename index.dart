import "dart:async" as EB;import "dart:html" as UB;import "dart:web_gl" as eB;import "dart:isolate" as iB;import "dart:typed_data" as JC;import "dart:math" as QD;import "dart:json" as WE;import "dart:mirrors" as TH;class UH{static const  VH="Chrome";static const  WH="Firefox";static const  XH="Internet Explorer";static const  YH="Safari";final  pG;final  minimumVersion;const UH(this.pG,[this.minimumVersion]);}class ZH{const ZH();}class aH{final  name;const aH(this.name);}class bH{const bH();}class cH{const cH();}const cF="_TexNormalsRandom";const dF=28;const XE="_TexVertices";const YE=29;const ZE="_TexNormals";const aE=30;main(){var g=(UB.query("#canvas0") as UB.CanvasElement).getContext3d(alpha:false,depth:true);if(g==null){print("webgl not supported");return;}var i=eF(g);new eH(new PG(g),i).start();} eF(k){var i=new fB();var j=i.asStream().asBroadcastStream();new oH(UB.query("#assetload")).bind(j);new dH().bind(j);var g=new XC(i);g.pB['img']=new lH();g.zB['img']=new jH();MG(k,g);return g;}class dH{dH(); bind( g){return g.listen(OE);} OE( g){print("AssetPackTraceEvent : ${g}");}}class fF{var NI=-1.0;var OI=0.0;var QI=0.0;var RI=false;get uG=>QI;get time=>NI;update(g){if(RI){QI=(g-OI);NI=NI+QI;}else{RI=true;}OI=g;}reset(){RI=false;NI=0.0;OI=0.0;QI=0.0;}}class eH{final  SB;final  VB;final  IE;final  uD=new fF();var SI;var TI;var UI=UB.query('#selectShader') as UB.SelectElement;var VI=UB.query('#selectMesh') as UB.SelectElement;var WI=UB.query('#subdivisionMesh') as UB.InputElement;var XI=UB.query('#loadShader') as UB.ButtonElement;var YI=UB.query('#applyShader') as UB.ButtonElement;var ZI=UB.query('#errorTxt') as UB.PreElement;var aI=UB.query('#showWireframe') as UB.CheckboxInputElement;var bI=UB.query('#showNormals') as UB.CheckboxInputElement;var cI=UB.query('#statsUpdate') as UB.PreElement;var dI=UB.query('#statsLoop') as UB.PreElement;var IH=new gH();var HH=new fH();var eI=new tH();final UF=new List<Function>();final fI=new aD()..min.wB(-4.0,-4.0,-1.0)..max.wB(4.0,4.0,4.0);eH(this.SB,g):VB=g,IE=new gF()..VB=g;start(){SB.GD();var l=new hH()..eD=(g,i){if(i-g.fD>1000){g.fD=i;var k="avg : ${g.cD}\nmax : ${g.max}\nmin : ${g.min}\nfps : ${1000/g.cD}\n";cI.text=k;if(i-g.QE>3000)g.reset();}};var o=new hH()..eD=(g,i){if(i-g.fD>1000){g.fD=i;var k="avg : ${g.cD}\nmax : ${g.max}\nmin : ${g.min}\nfps : ${1000/g.cD}\n";dI.text=k;if(i-g.QE>3000)g.reset();}};SB.add(new RC()..eC=(new Map()..["dt"]=((j)=>j.m.uniform1f(j.getUniformLocation('dt'),uD.uG))..["time"]=((j)=>j.m.uniform1f(j.getUniformLocation('time'),uD.time))));var AB=new oE.HI(SB.m.canvas)..KB.position.wB(0.0,0.0,6.0)..KB.gD.wB(0.0,0.0,0.0)..KB.IF(fI,0.1,0.1);SB.dD=AB;gI().then((DB){SB.MF.add(IE.EH());hI();});q(BB){l.start();UB.window.animationFrame.then(q);uD.update(BB);UF.forEach((u)=>u(uD));SB.run();l.stop();o.stop();o.start();}UB.window.animationFrame.then(q);BH();oG();UI.selectedIndex=0;RF(UI.value).then((iI){apply();});}BH(){SI=DF((AF as dynamic).mG.xG(UB.query("#vertex"),EF({"mode":"glsl","lineNumbers":true})).tG);TI=DF((AF as dynamic).mG.xG(UB.query("#fragment"),EF({"mode":"glsl","lineNumbers":true})).tG);}oG(){XI.onClick.listen((iI)=>RF(UI.value));YI.onClick.listen((iI)=>apply());}RF( i){var j=Uri.parse("${i}.vert");var k=Uri.parse("${i}.frag");return EB.Future.wait([UB.HttpRequest.request(j.toString(),method:'GET'),UB.HttpRequest.request(k.toString(),method:'GET')]).then((g){SI.LH(g[0].responseText);TI.LH(g[1].responseText);});}GH(g)=>eI.find(g,SI.yG(),TI.yG());FH(){var i=int.parse(WI.value);var g=null;switch (VI.value){case 'box24':g=zD(dx:2.0,dy:1.0,dz:0.5,ty:1.0);break;case 'box24-t':g=zD(dx:2.0,dy:1.0,dz:0.5,tx:2.0,ty:1.0,tz:0.5);break;case 'cube8':g=zF(dx:0.5,dy:0.5,dz:0.5);break;case 'sphereL':g=JG(subdivisionsAxis:i,subdivisionsHeight:i);break;default:g=zD(dx:0.5,dy:0.5,dz:0.5);}if(aI.checked){g.kB=uF(g.hB);g.hB=null;}return g;}apply(){try {ZI.text='';var i=GH(SB.m);IH.nG(SB,i);HH.apply(SB,i,UF,FH(),bI.checked);}catch (g,j){ZI.text=g.toString();print(g);print(j);}} gI(){return EB.Future.wait([IE.GD(),VB.uB('shader_depth_light','shaderProgram','packages/glf/shaders/depth_light{.vert,.frag}',null,null),VB.uB('shader_deferred_normals','shaderProgram','packages/glf/shaders/deferred{.vert,_normals.frag}',null,null),VB.uB('shader_deferred_vertices','shaderProgram','packages/glf/shaders/deferred{.vert,_vertices.frag}',null,null),VB.uB('filter2d_blend_ssao','filter2d','packages/glf/shaders/filters_2d/blend_ssao.frag',null,null),VB.uB('texNormalsRandom','tex2d','normalmap.png',null,null)]).then((g)=>VB);}hI(){jI();kI();}jI(){var i=new oE()..YB=256..XB=256..KB.hD=GF*55.0..KB.aspectRatio=1.0..KB.position.wB(2.0,2.0,4.0)..KB.gD.wB(0.0,0.0,0.0)..KB.IF(fI,0.1,0.1);var j=new wH(SB.m)..ID(width:i.YB,height:i.XB);var o=VB['shader_depth_light'];var l=i.SF()..GB=o..nB=i.nB..fC=(g){g.m.bindFramebuffer(eB.FRAMEBUFFER,j.buffer);g.m.viewport(i.x,i.y,i.YB,i.XB);g.m.clearColor(1.0,1.0,1.0,1.0);g.m.clear(eB.COLOR_BUFFER_BIT|eB.DEPTH_BUFFER_BIT);i.iC(g);};var k=new RC()..eC=(new Map()..["sLightDepth"]=((g)=>gB(g,j.VC,31,"sLightDepth"))..["lightFar"]=((g)=>g.m.uniform1f(g.getUniformLocation('lightFar'),i.KB.qC))..["lightNear"]=((g)=>g.m.uniform1f(g.getUniformLocation('lightNear'),i.KB.rC))..["lightConeAngle"]=((g)=>g.m.uniform1f(g.getUniformLocation('lightConeAngle'),i.KB.hD*hG))..["lightProj"]=((g)=>SC(g,i.KB.LD,"lightProj"))..["lightView"]=((g)=>SC(g,i.KB.oB,"lightView"))..["lightRot"]=((g)=>VD(g,i.KB.vB,"lightRot"))..["lightProjView"]=((g)=>SC(g,i.KB.rD,"lightProjView")));SB.add(k);SB.yC(k);SB.yC(l);SB.rG=j.VC;}kI(){var g=lI(SB.dD,VB['shader_deferred_normals'],ZE,aE);var i=lI(SB.dD,VB['shader_deferred_vertices'],XE,YE);mI(g.VC,i.VC,VB['texNormalsRandom']);}lI(i,g,l,q){var j=new wH(SB.m)..ID(width:i.YB,height:i.XB,type:eB.FLOAT);var o=new RC()..GB=g..fC=(g){g.m.bindFramebuffer(eB.FRAMEBUFFER,j.buffer);g.m.viewport(i.x,i.y,i.YB,i.XB);g.m.clearColor(1.0,1.0,1.0,1.0);g.m.clear(eB.COLOR_BUFFER_BIT|eB.DEPTH_BUFFER_BIT);i.iC(g);};var k=new RC()..eC=(new Map()..[l]=((g)=>gB(g,j.VC,q,l)));SB.add(k);SB.yC(k);SB.yC(o);return j;}mI( j, l, k){var i=new SD.GI(VB['filter2d_blend_ssao'])..cfg=(g){g.m.uniform2f(g.getUniformLocation('_Attenuation'),1.0,5.0);g.m.uniform1f(g.getUniformLocation('_SamplingRadius'),15.0);g.m.uniform1f(g.getUniformLocation('_OccluderBias'),0.05);gB(g,j,aE,ZE);gB(g,l,YE,XE);gB(g,k,dF,cF);};SB.MF.insert(0,i);}}class gF{var VB;GD(){return EB.Future.wait([VB.uB('filter2d_identity','filter2d','packages/glf/shaders/filters_2d/identity.frag',null,null),VB.uB('filter2d_brightness','filter2d','packages/glf/shaders/filters_2d/brightness.frag',null,null),VB.uB('filter2d_convolution3x3','filter2d','packages/glf/shaders/filters_2d/convolution3x3.frag',null,null),VB.uB('filter2d_x_waves','filter2d','packages/glf/shaders/filters_2d/x_waves.frag',null,null)]).then((g)=>VB);}EH(){return VB['filter2d_identity'];}}class fH{var CD;var PD;var RB=new BE();var JD;apply(i,j,g, l,k){nI(i,g);oI(i,j,g,l,k);}nI(g,i){g.YF(RB);if(CD!=null){g.remove(CD);CD=null;}if(PD!=null){i.remove(PD);PD=null;}}oI(j,g,BB,q,TB){RB.mD=q;var i=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/dirt.jpg"));var l=PC(g.m,new JC.Uint8List.fromList([0,0,120]),Uri.parse("_images/shaders_offest_normalmap.jpg"));var cB=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/burnMap.png"));var ZB=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/growMap.png"));var NB=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/linear.png"));var OB=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/matcap/matcap0.png"));var PB=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/matcap/matcap1.png"));var IB=PC(g.m,new JC.Uint8List.fromList([120,120,120,255]),Uri.parse("_images/matcap/matcap2.jpg"));var dB=new sE()..GB=g..cfg=(g){g.m.uniform3f(g.getUniformLocation(TD),0.5,0.5,0.5);gB(g,i,0);gB(g,l,1,'_NormalMap0');gB(g,cB,3,'_DissolveMap0');gB(g,ZB,4,'_DissolveMap1');gB(g,NB,5,'_DissolveMap2');gB(g,OB,10,'_MatCap0');gB(g,PB,11,'_MatCap1');gB(g,IB,12,'_MatCap2');};j.HF(RB,dB);PD=(o){RB.WC.sD();RB.WC.KH((o.time%5000.0)/5000.0*2*QD.PI);WD(RB.WC,RB.sC);};BB.add(PD);if(TB){var AB=wF(RB.mD);var k=new sH()..setData(g.m,AB);var DB=LG(g.m,Uri.parse("packages/glf/shaders/default.vert"),Uri.parse("packages/glf/shaders/default.frag"));DB.then((u){CD=new RC()..GB=u..at=(g){g.m.uniform3f(g.getUniformLocation(TD),0.8,0.8,0.8);WD(RB.WC,RB.sC);SC(g,RB.WC,lE);VD(g,RB.sC,kE);gB(g,i,0);gB(g,l,1);k.OF(g);k.LF(g);};j.add(CD);});}}}class gH{var RB=new BE();nG(g,i){g.YF(RB);oI(g,i);}oI(j,g){RB.mD=vF(dx:3.0,dy:3.0);WD(RB.WC,RB.sC);var i=new sE()..GB=g..cfg=(g){g.m.uniform3f(g.getUniformLocation(TD),0.0,0.5,0.5);};j.HF(RB,i);}}class hH{var eD;var fD=0.0;var QE=0.0;var min;var max;var total;var count;var pI;final qI=UB.window.performance;get cD=>(count==0)?0.0:total/count;hH(){reset();start();}start(){pI=qI.now();}stop(){var g=qI.now();QH(g-pI);if(eD!=null){eD(this,g);}}QH( g){if(min>g)min=g;if(max<g)max=g;count++ ;total+= g;}reset(){QE=qI.now();min=double.MAX_FINITE;max=double.MIN_POSITIVE;total=0.0;count=0;}}class XC{final  zB=new Map<String,KC>();final  pB=new Map<String,OC>();final  OD;XC([g]):OD=(g==null)?new pH():g{tI=new YC(this,'root');zB['json']=new kH();zB['text']=new nH();zB['pack']=new iH(this);zB['textmap']=new jH();zB['imagemap']=new jH();pB['textmap']=new mH(new bE());pB['imagemap']=new mH(new lH());pB['json']=new bE();pB['text']=pB['json'];pB['pack']=pB['json'];}var tI; get root=>tI; iD( g)=>root.iD(g); operator[]( g)=>iD(g); uB( j, k, l, i, g){return root.uB(j,k,l,i,g);} AJ( g){if(g.KE==null){OD.dC(g,'no loader registered for ${g.type}');return new EB.Future.value(g);}if(g.FD==null){OD.dC(g,'no importer registered for ${g.type}');return new EB.Future.value(g);}g.uI='Loading';return g.KE.load(g,OD).then((i){g.uI='Importing';return g.FD.import(i,g,OD);});}}class mH extends OC{var rI;mH(this.rI); load( i, g){var q=new bE();var u=q.load(i,g);return u.then((AB){var j;try {j=WE.parse(AB);}on FormatException catch (IB){g.dC(i,IB.message);return new EB.Future.value(null);}var l={};var o=[] ;var PB=Uri.parse(i.url);j.forEach((k,NB){var BB=PB.resolve(NB).toString();var OB=new t(null,k,BB,'',null,{},null,{});o.add(rI.load(OB,g).then((DB){l[k]=DB;}));});return EB.Future.wait(o).then((wI){return l;});});} delete( g){}}class aB{static const dE='PackImportStart';static const eE='PackImportEnd';static const fE='AssetLoadStart';static const gE='AssetLoadEnd';static const iF='AssetLoadError';static const hE='AssetImportStart';static const iE='AssetImportEnd';static const jF='AssetImportError';final  type;final  label;final  ME;aB(this.type,this.label,this.ME); TE(){var g=new Map();g['type']=type;g['label']=label;g['timestamp']=ME;} toString(){return '${ME}, ${type}, ${label}';}}class nH extends KC{ initialize( g){g.QB='';}EB.Future<t> import( j, g, i){i.zC(g);if(j is String){g.QB=j;}else{i.nC(g,"A text asset was not a String.");}i.cC(g);return new EB.Future.value(g);} delete( g){}}class bE extends OC{ load( j, g){return OC.hF(j,'text',(i)=>i.responseText,g);} delete( g){}}class iH extends KC{final  UC;iH(this.UC); initialize( g){g.QB=new YC(UC,g.name);g.QB.sI=g.KD;}EB.Future<t> import( k, g, i){i.VF(g);i.zC(g);if(k==null){i.nC(g,"A pack asset was not available.");i.cC(g);i.pD(g);return new EB.Future.value(g);}var PB=Uri.parse(g.url);var q;if(k is String){try {q=WE.parse(k);}on FormatException catch (IB){i.nC(g,IB.message);i.cC(g);i.pD(g);return new EB.Future.value(g);}}var l=g.QB;var DB=new jE.lF(q);var u=new List<EB.Future<t>>();DB.mB.values.forEach((j){var BB=PB.resolve(j.url).toString();var NB=j.name;var AB=j.type;if(AB==''){return;}var o=l.WF(NB,AB,BB,j.HD,j.ED);var OB=UC.AJ(o).then((wI){o.uI='Ok';});u.add(OB);});return EB.Future.wait(u).then((TB){i.cC(g);i.pD(g);return new EB.Future.value(l);});} delete( g){if(g==null){return;}}}class jH extends KC{ initialize( g){g.QB=null;}EB.Future<t> import( j, g, i){i.zC(g);try {g.QB=j;return new EB.Future.value(g);}finally {i.cC(g);}} delete( g){}}class kH extends KC{ initialize( g){g.QB={};}EB.Future<t> import( j, g, i){i.zC(g);try {if(j is String){try {var k=WE.parse(j);g.QB=k;}on FormatException catch (l){i.nC(g,l.message);}}else{i.nC(g,"A text asset was not a String.");}return new EB.Future.value(g);}finally {i.cC(g);}} delete( g){}}class lH extends OC{ load( g, j){j.DE(g);var l=new EB.Completer<FI>();var i=new UB.ImageElement();i.onLoad.listen((k){j.oC(g);l.complete(i);});i.onError.listen((k){j.dC(g,"${k.runtimeType} : ${k.type}");j.oC(g);l.complete(null);});i.src=g.url;return l.future;} delete( g){}}typedef  cE( ratio, change, base);abstract class OC{static  hF( i, q, o(HttpRequest), j){j.DE(i);var k=new EB.Completer<FI>();var g=new UB.HttpRequest();g.open('GET',i.url,async:true);g.responseType=q;g.onLoad.listen((l){if((g.status>=200&&g.status<300)||g.status==0||g.status==304){j.oC(i);k.complete(o(g));}else{j.dC(i,"http status code rejected : ${g.status} : ${g.statusText}");j.oC(i);k.complete(null);}});g.onError.listen((l){j.dC(i,"http status code rejected : ${g.status} : ${g.statusText}");j.oC(i);k.complete(null);});g.send();return k.future;} load( i, g); delete( g);}abstract class KC{ initialize( g);EB.Future<t> import( i, j, g); delete( g);}class t{final  KD;final  name;final  type;final  KE;final  FD;final  DH;final  AH;final  url;var uI=''; get status=>uI;var vI; get QB=>vI;set QB( g){vI=g;uI='OK';} get CH=>type=='pack';t(this.KD,this.name,this.url,this.type,this.KE,this.DH,this.FD,this.AH); get path=>'${KD.path}.${name}'; xI(){if(FD!=null){FD.delete(vI);}}}class YC{final  UC;final  name;final  mB=new Map<String,t>();var sI; get parent=>sI; get path{if(parent==null){return '';}var g=parent.path;if(g==''){return name;}else{return '${g}.${name}';}}YC(this.UC,this.name); type( i){var g=mB[i];if(g!=null){return g.type;}return null;} url( i){var g=mB[i];if(g!=null){return g.url;}return null;} WF( i, k, q, l, u){if(jE.mF(i)==false){throw new ArgumentError('${i} is an invalid name.');}var g=mB[i];if(g!=null){throw new ArgumentError('${i} already exists.');}var o=UC.pB[k];var j=UC.zB[k];g=new t(this,i,q,k,o,l,j,l);if(j!=null){j.initialize(g);}if(j==null){g.uI='No importer available.';}else if(o==null){g.uI='No loader available.';}else{g.uI='OK';}mB[i]=g;return g;} uB( j, k, o, i, g){var l=WF(j,k,o,i,g);return UC.AJ(l);} iD( g){var j=g.split(".");var i=FJ(g,j,false);if(i!=null){return i.QB;}return null;} operator[]( g)=>iD(g); FJ( j, g, k){if(g.length==0){if(k==false){return null;}throw new ArgumentError('${j} does not exist.');}var o=g.removeAt(0);var i=mB[o];if(i==null){if(k==false){return null;}throw new ArgumentError('${j} does not exist.');}if(i.CH&&g.length>0){var l=i.QB;return l.FJ(j,g,k);}if(g.length>0){if(k==false){return null;}throw new ArgumentError('${j} does not exist.');}return i;} get length=>mB.length; clear(){xI();} xI(){mB.forEach((i,g){g.xI();});mB.clear();}}class oH{static  kF( g, j, i){return j*g+i;}var yI;var zI;final  ease;var displayBackward=true;var BJ=0;var CJ=0;var DJ=0.0;oH( g,{ this.ease: kF,this.displayBackward: true}){if(g is UB.ProgressElement){yI=g;}else{zI=g;}} bind( g){return g.listen(OE);} EJ(){if(BJ==CJ){BJ=0;CJ=0;DJ=0.0;}} OE( i){switch (i.type){case aB.dE:case aB.hE:case aB.fE:EJ();BJ+= 1;break;case aB.eE:case aB.gE:case aB.iE:CJ+= 1;break;}var g=(BJ==0)?0.0:CJ/BJ;DJ=(displayBackward)?g:QD.max(DJ,g);if(yI!=null){yI.value=ease(DJ,yI.max,0).toInt();}if(zI!=null){zI.style.width=ease(DJ,100,0).toString()+"%";}}}class fB{final GJ=new EB.StreamController<aB>(sync:true); asStream()=>GJ.stream; VF( g)=>MC(g,aB.dE,null); pD( g)=>MC(g,aB.eE,null); DE( g)=>MC(g,aB.fE,null); oC( g)=>MC(g,aB.gE,null); dC( i, g)=>MC(i,aB.iF,g); zC( g)=>MC(g,aB.hE,null); cC( g)=>MC(g,aB.iE,null); nC( i, g)=>MC(i,aB.jF,g); MC( i, l, g){var k=(g==null)?i.url:"${i.url} >> ${g}";var j=(UB.window.performance.now()*1000).toInt();var o=new aB(l,k,j);GJ.add(o);}}class pH extends fB{ VF( g){} pD( g){} DE( g){} oC( g){} dC( i, g){} zC( g){} cC( g){} nC( i, g){} MC( j, i, g){}}class tC{final  name;final  url;var type;final  HD;final  ED; TE(){var g=new Map();g['url']=url;g['type']=type;if(HD!=null&&!HD.isEmpty){g['loadArguments']=HD;}if(ED!=null&&!ED.isEmpty){g['importArguments']=ED;}return g;}tC(this.name,this.url,this.type,this.HD,this.ED);static  lF( j, g){var l=g['url'];var o=g['type'];var i=g['loadArguments'];var k=g['importArguments'];var q=new tC(j,l,o,i,k);return q;}}class jE{static  mF( g){return g!='';}final  mB=new Map<String,tC>(); clear(){mB.clear();} TE(){var i=new Map<String,Map>();mB.forEach((j,g){i[g.name]=g.TE();});return i;}jE.lF( i){if(i==null){return;}i.forEach((g,k){var j=tC.lF(g,k);mB[g]=j;});}}abstract class nF{static  oF( j){var i=new StringBuffer();for(var g in j){i.write('${g<16?'0':''}${g.toRadixString(16)}');}return i.toString();}}const ZC=0xff;const lC=0xffffffff;class qH extends qF{qH():HJ=new List(80),super(16,5,true){IJ[0]=0x67452301;IJ[1]=0xEFCDAB89;IJ[2]=0x98BADCFE;IJ[3]=0x10325476;IJ[4]=0xC3D2E1F0;} JJ( u){assert(u.length==16);var o=IJ[0];var i=IJ[1];var l=IJ[2];var k=IJ[3];var q=IJ[4];for(var g=0;g<80;g++ ){if(g<16){HJ[g]=u[g];}else{var AB=HJ[g-3]^HJ[g-8]^HJ[g-14]^HJ[g-16];HJ[g]=yD(AB,1);}var j=QJ(QJ(yD(o,5),q),HJ[g]);if(g<20){j=QJ(QJ(j,(i&l)|(~i&k)),0x5A827999);}else if(g<40){j=QJ(QJ(j,(i^l^k)),0x6ED9EBA1);}else if(g<60){j=QJ(QJ(j,(i&l)|(i&k)|(l&k)),0x8F1BBCDC);}else{j=QJ(QJ(j,i^l^k),0xCA62C1D6);}q=k;k=l;l=yD(i,30);i=o;o=j&lC;}IJ[0]=QJ(o,IJ[0]);IJ[1]=QJ(i,IJ[1]);IJ[2]=QJ(l,IJ[2]);IJ[3]=QJ(k,IJ[3]);IJ[4]=QJ(q,IJ[4]);}var HJ;}const pF=8;const RD=4; yD( g, j){var i=j&31;return ((g<<i)&lC)|((g&lC)>>(32-i));}abstract class qF implements rF{qF( this.KJ, this.LJ, this.MJ):NJ=[] {OJ=new List(KJ);IJ=new List(LJ);}add( g){if(PJ){throw new StateError('Hash update method called after digest was retrieved');}RJ+= g.length;NJ.addAll(g);SJ();} close(){if(PJ){return TJ();}PJ=true;UJ();SJ();assert(NJ.length==0);return TJ();}JJ( g);QJ(i,g)=>(i+g)&lC;VJ(i,g)=>(i+g-1)&-g;TJ(){var i=[] ;for(var g=0;g<IJ.length;g++ ){i.addAll(WJ(IJ[g]));}return i;}XJ( i, g){assert((i.length-g)>=(KJ*RD));for(var k=0;k<KJ;k++ ){var q=MJ?i[g]:i[g+3];var o=MJ?i[g+1]:i[g+2];var u=MJ?i[g+2]:i[g+1];var l=MJ?i[g+3]:i[g];g+= 4;var j=(q&0xff)<<24;j|= (o&ZC)<<16;j|= (u&ZC)<<8;j|= (l&ZC);OJ[k]=j;}}WJ( i){var g=new List(RD);g[0]=(i>>(MJ?24:0))&ZC;g[1]=(i>>(MJ?16:8))&ZC;g[2]=(i>>(MJ?8:16))&ZC;g[3]=(i>>(MJ?0:24))&ZC;return g;}SJ(){var i=NJ.length;var j=KJ*RD;if(i>=j){var g=0;for(;(i-g)>=j;g+= j){XJ(NJ,g);JJ(OJ);}NJ=NJ.sublist(g,i);}}UJ(){NJ.add(0x80);var j=RJ+9;var l=KJ*RD;var k=VJ(j,l);var o=k-j;for(var i=0;i<o;i++ ){NJ.add(0);}var g=RJ*pF;assert(g<QD.pow(2,32));if(MJ){NJ.addAll(WJ(0));NJ.addAll(WJ(g&lC));}else{NJ.addAll(WJ(g&lC));NJ.addAll(WJ(0));}}final  KJ;final  LJ;final  MJ;var RJ=0;var NJ;var OJ;var IJ;var PJ=false;}abstract class rF{add( g); close();}class sF{static  oF( g){return nF.oF(g);}}class SD{static const tF="""
const vec2 ma = vec2(0.5,0.5);
attribute vec2 ${uC}0;
varying vec2 vTexCoord0;
 
void main(void) {
  gl_Position = vec4(${uC}0, 0.0, 1.0);
  vTexCoord0 = ${uC}0 * ma + ma;
}
""";final  GB;var cfg;SD(g, i,[ this.cfg]):GB=new bB(g,tF,i);SD.GI( g):GB=g.GB,cfg=g.cfg;}uF( j){var k=new JC.Uint16List(j.length*2);for(var g=0;g<j.length;g=g+3){for(var i=0;i<3;i++ ){var l=j[g+i];var o=j[g+(i+1)%3];k[(g+i)*2]=l;k[(g+i)*2+1]=o;}}return k;}class rH{var aspectRatio,hD;var rC,qC;var left,right,bottom,top;var QF=false;final position=new v(0.0,0.0,1.0);final gD=new v(0.0,0.0,0.0);final RH=new v(0.0,1.0,0.0);final LD=new CB.KI();final oB=new CB.MI();final vB=new JB.MI();final rD=new CB.KI();aF(){if(QF){lG(LD,left,right,bottom,top,rC,qC);}else{jG(LD,hD,aspectRatio,rC,qC);}bF();}SH(){iG(oB,position,gD,RH);vB.h[0]=oB.h[0];vB.h[1]=oB.h[1];vB.h[2]=oB.h[2];vB.h[3]=oB.h[4];vB.h[4]=oB.h[5];vB.h[5]=oB.h[6];vB.h[6]=oB.h[8];vB.h[7]=oB.h[9];vB.h[8]=oB.h[10];bF();}bF(){LD.pC(rD);rD.multiply(oB);}IF( j, i, o){var g=new LB(i,o);var l=(gD-position).NE();var k=HG(j);IG(k,l,position,g);qC=g.y;rC=QD.max(i,g.x);}}vF({ dx: 0.5, dy: 0.5}){return new mC()..MB=new JC.Float32List.fromList([-dx,-dy,0.0,dx,-dy,0.0,dx,dy,0.0,-dx,dy,0.0])..WB=new JC.Float32List.fromList([0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0])..hB=new JC.Uint16List.fromList([0,1,2,2,0,3])..lB=new JC.Float32List.fromList([0.0,0.0,1.0,0.0,1.0,1.0,0.0,1.0]);}wF( i){var g=new mC();if(i.WB==null||i.WB.length<3)return g;var q=i.WB.length~/3;g.MB=new JC.Float32List(q*3*2);g.kB=new JC.Uint16List(q*2);for(var l=0;l<q;l++ ){var o=l*2;var j=l*3;var k=l*6;g.MB[k+0]=i.MB[j+0];g.MB[k+1]=i.MB[j+1];g.MB[k+2]=i.MB[j+2];g.MB[k+3]=i.MB[j+0]+i.WB[j+0];g.MB[k+4]=i.MB[j+1]+i.WB[j+1];g.MB[k+5]=i.MB[j+2]+i.WB[j+2];g.kB[o+0]=o;g.kB[o+1]=o+1;}return g;}class xF{final YJ=uC+"0";var ZJ;var m;GD(g){this.m=g;ZJ=g.createBuffer();g.bindBuffer(eB.ARRAY_BUFFER,ZJ);g.bufferDataTyped(eB.ARRAY_BUFFER,new JC.Float32List.fromList([-1.0,-1.0,1.0,-1.0,-1.0,1.0,-1.0,1.0,1.0,-1.0,1.0,1.0]),eB.STATIC_DRAW);}jD(i){var g=i.getAttribLocation(YJ);m.bindBuffer(eB.ARRAY_BUFFER,ZJ);m.enableVertexAttribArray(g);m.vertexAttribPointer(g,2,eB.FLOAT,false,0,0);m.drawArrays(eB.TRIANGLES,0,6);}delete(){m.deleteBuffer(ZJ);}} PC( i, o,[ g,l(RenderingContext,Texture,ImageElement)=nE]){var j=i.createTexture();if(g!=null){BG(g).then((k){l(i,j,k);});}return j;}const yF="_Vertex";const uC="_TexCoord";zF({ dx: 0.5, dy: 0.5, dz: 0.5}){return new mC()..MB=new JC.Float32List.fromList([-dx,-dy,dz,dx,-dy,dz,dx,dy,dz,-dx,dy,dz,-dx,-dy,-dz,dx,-dy,-dz,dx,dy,-dz,-dx,dy,-dz])..WB=new JC.Float32List.fromList([-0.33,-0.33,0.33,0.33,-0.33,0.33,0.33,0.33,0.33,-0.33,0.33,0.33,-0.33,-0.33,-0.33,0.33,-0.33,-0.33,0.33,0.33,-0.33,-0.33,0.33,-0.33])..hB=new JC.Uint16List.fromList([0,1,2,2,0,3,4,5,6,6,4,7,1,2,6,6,1,5,0,3,7,7,0,4,3,2,6,6,3,7,0,1,5,5,0,4])..lB=new JC.Float32List.fromList([0.0,0.0,1.0,0.0,1.0,1.0,0.0,1.0,1.0,0.0,0.0,0.0,0.0,1.0,1.0,1.0]);}const TD="_Color";const AG="_Normal";const kE="_NormalMatrix";const lE="_ModelMatrix"; BG( j){var i=new EB.Completer<UB.ImageElement>();var g=new UB.ImageElement();g.onLoad.listen((k){i.complete(g);});g.src=j.toString();return i.future;}const CG="_ViewMatrix";const DG="_RotMatrix";const EG="_ProjectionMatrix";class sH{final MB=new uH()..MD=yF;final WB=new uH()..MD=AG;final lB=new uH()..MD=uC+'0'..spacing=2;final yB=new uH()..MD=TD;final hB=new vH();final kB=new vH();setData( i, g,[j=true]){if(g.MB!=null){if(j)qG(g);MB.setData(i,g.MB);}if(g.WB!=null){WB.setData(i,g.WB);}if(g.lB!=null){lB.setData(i,g.lB);}if(g.yB!=null){yB.setData(i,g.yB);}if(g.hB!=null)hB.setData(i,g.hB);if(g.kB!=null)kB.setData(i,g.kB);}qG( g){var j=g.MB.length/MB.spacing;if(g.WB!=null&&j!=g.WB.length/WB.spacing)throw new Exception("expecting ${WB.spacing*j} length for MeshDef.normals (${g.WB.length})");if(g.lB!=null&&j!=g.lB.length/lB.spacing)throw new Exception("expecting ${lB.spacing*j} length for MeshDef.texCoords (${g.lB.length})");if(g.yB!=null&&j!=g.yB.length/yB.spacing)throw new Exception("expecting ${yB.spacing*j} length for MeshDef.texCoords (${g.yB.length})");if(g.hB!=null){for(var i=0;i<g.hB.length;i++ ){if(g.hB[i]<0||g.hB[i]>=j)throw new Exception("expecting value of MeshDef.triangles to be in [0, ${j}[ triangles[${i}] = ${g.hB[i]}");}}if(g.kB!=null){for(var i=0;i<g.kB.length;i++ ){if(g.kB[i]<0||g.kB[i]>=j)throw new Exception("expecting value of MeshDef.lines to be in [0, ${j}[ lines[${i}] = ${g.kB[i]}");}}}OF( g){WB.kD(g);lB.kD(g);yB.kD(g);MB.kD(g);}LF( g,[ i=eB.TRIANGLES]){hB.drawElements(g,i);kB.drawElements(g,eB.LINES);}}const FG="_ProjectionViewMatrix";const GG="_PixelSize";class mE{final  m;final  hC=new List<SD>();var tD;final aJ;final bJ;var jC;var PE;mE(g, this.jC):this.m=g,aJ=new wH(g),bJ=new wH(g){aJ.ID(width:jC.YB,height:jC.XB,hasDepthBuff:false);bJ.ID(width:jC.YB,height:jC.XB,hasDepthBuff:false);PE=new xF();PE.GD(g);}run(){if(hC.length==0)return;jC.nB(m);var l=tD;var j=aJ;for(var i=0;i<hC.length; ++i){if(i>0){l=(j==aJ)?bJ.VC:aJ.VC;}if(i==hC.length-1){m.bindFramebuffer(eB.FRAMEBUFFER,null);}else{m.bindFramebuffer(eB.FRAMEBUFFER,j.buffer);j=(j==aJ)?bJ:aJ;}var g=hC[i].GB;var k=hC[i].cfg;g.m.useProgram(g.AC);jC.iC(g);if(k!=null)k(g);gB(g,l,0);PE.jD(g);}m.bindFramebuffer(eB.FRAMEBUFFER,null);}}class bB{final  m;var AC;final cJ=new Map<String,int>();final dJ=new Map<String,eB.UniformLocation>();var eJ;var fJ;final gJ=new List<QC>();final hJ=new List<QC>();bB(this.m, g, i){eJ=rE(m,g,eB.VERTEX_SHADER);fJ=rE(m,i,eB.FRAGMENT_SHADER);AC=KG(m,eJ,fJ);} getAttribLocation( i){var g=cJ[i];if(g==null){g=m.getAttribLocation(AC,i);cJ[i]=g;}return g;} getUniformLocation( i){var g=dJ[i];if(g==null){g=m.getUniformLocation(AC,i);dJ[i]=g;}return g;}sG([ i]){var k=(i==null)?[] :i.cJ.keys;cJ.forEach((j,g){if(g!=-1&&!k.contains(j)){m.disableVertexAttribArray(g);}});}delete(){if(fJ!=null){m.detachShader(AC,fJ);m.deleteShader(fJ);fJ=null;}if(eJ!=null){m.detachShader(AC,eJ);m.deleteShader(eJ);eJ=null;}if(AC!=null){m.deleteProgram(AC);AC=null;}}}nE( g, i, j){g.bindTexture(eB.TEXTURE_2D,i);g.pixelStorei(eB.UNPACK_FLIP_Y_WEBGL,1);g.texImage2DImage(eB.TEXTURE_2D,0,eB.RGBA,eB.RGBA,eB.UNSIGNED_BYTE,j);g.texParameteri(eB.TEXTURE_2D,eB.TEXTURE_MAG_FILTER,eB.LINEAR);g.texParameteri(eB.TEXTURE_2D,eB.TEXTURE_MIN_FILTER,eB.LINEAR_MIPMAP_NEAREST);g.generateMipmap(eB.TEXTURE_2D);g.bindTexture(eB.TEXTURE_2D,null);return i;}zD({ dx: 0.5, dy: 0.5, dz: 0.5, tx: 1.0, ty: 1.0, tz: 1.0}){return new mC()..MB=new JC.Float32List.fromList([-dx,-dy,dz,dx,-dy,dz,dx,dy,dz,-dx,dy,dz,-dx,-dy,-dz,-dx,dy,-dz,dx,dy,-dz,dx,-dy,-dz,-dx,dy,-dz,-dx,dy,dz,dx,dy,dz,dx,dy,-dz,-dx,-dy,-dz,dx,-dy,-dz,dx,-dy,dz,-dx,-dy,dz,dx,-dy,-dz,dx,dy,-dz,dx,dy,dz,dx,-dy,dz,-dx,-dy,-dz,-dx,-dy,dz,-dx,dy,dz,-dx,dy,-dz])..WB=new JC.Float32List.fromList([0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,0.0])..hB=new JC.Uint16List.fromList([0,1,2,0,2,3,4,5,6,4,6,7,8,9,10,8,10,11,12,13,14,12,14,15,16,17,18,16,18,19,20,21,22,20,22,23])..lB=new JC.Float32List.fromList([0.0,0.0,tx,0.0,tx,ty,0.0,ty,tx,0.0,tx,ty,0.0,ty,0.0,0.0,0.0,tz,0.0,0.0,tx,0.0,tx,tz,tx,tz,0.0,tz,0.0,0.0,tx,0.0,tz,0.0,tz,ty,0.0,ty,0.0,0.0,0.0,0.0,tz,0.0,tz,ty,0.0,ty]);}HG( g){var i=new List<v>(8);i[0]=new v(g.min.x,g.min.y,g.min.z);i[1]=new v(g.min.x,g.min.y,g.max.z);i[2]=new v(g.min.x,g.max.y,g.min.z);i[3]=new v(g.max.x,g.min.y,g.min.z);i[4]=new v(g.max.x,g.max.y,g.max.z);i[5]=new v(g.max.x,g.max.y,g.min.z);i[6]=new v(g.max.x,g.min.y,g.max.z);i[7]=new v(g.min.x,g.max.y,g.max.z);return i;}gB( g, k,[ j=0, i]){if(i==null)i="_Tex${j}";g.m.activeTexture(eB.TEXTURE0+j);g.m.bindTexture(eB.TEXTURE_2D,k);g.m.uniform1i(g.getUniformLocation(i),j);}class tH{final iJ=new Map<String,bB>();find(o, j, k){var i=new qH();i.add(j.codeUnits);i.add(k.codeUnits);var l=sF.oF(i.close());var g=iJ[l];if(g==null){g=new bB(o,j,k);iJ[l]=g;}return g;}}class AE{final  m;final jJ=new List<bB>();final kJ=new List<UD>();final lJ=new List<UD>();final mJ=new List<QC>();final nJ=new List<UD>();final oJ=new List<UD>();final pJ=new List<qE>();final qJ=new List<qE>();final rJ=new Map<String,QC>();final sJ=new List<QC>();AE(this.m);register( g){if((g.GB!=null)&&(g.GB.m!=m))throw new Exception("ProgramsRunner only accept request about same RenderingContext : req.ctx.gl != this.gl");if(g.nB!=null)kJ.add(g.nB);if(g.BD!=null)lJ.add(g.BD);if(g.bD!=null)nJ.add(g.bD);if(g.nD!=null)pJ.add(g.nD);if(g.oD!=null)qJ.add(g.oD);if(g.gC!=null)mJ.add(g.gC);if(g.AD!=null)sJ.add(g.AD);if(g.eC!=null)g.eC.forEach((j,k){rJ[j]=k;});if(g.GB!=null){var i=!jJ.contains(g.GB);if(i){jJ.add(g.GB);}if(g.fC!=null)g.GB.gJ.add(g.fC);if(g.at!=null)g.GB.hJ.add(g.at);if(i){pJ.forEach((l)=>l(this,g.GB));}}else{if(g.fC!=null)throw new Exception("try to register 'before' but no 'ctx' defined");if(g.at!=null)throw new Exception("try to register 'at' but no 'ctx' defined");}}unregister( g){if(g.ZF!=null)oJ.add(g.ZF);if(g.BD!=null)lJ.remove(g.BD);if(g.bD!=null)nJ.remove(g.bD);if(g.nD!=null)pJ.remove(g.nD);if(g.oD!=null)pJ.remove(g.oD);if(g.gC!=null)mJ.remove(g.gC);if(g.AD!=null)sJ.remove(g.AD);if(g.eC!=null)g.eC.keys.forEach((i){var k=rJ.remove(i);});if(g.GB!=null){if(g.fC!=null)g.GB.gJ.remove(g.fC);if(g.at!=null){g.GB.hJ.remove(g.at);if(g.GB.hJ.length==0){qJ.forEach((j)=>j(this,g.GB));jJ.remove(g.GB);}}}}run(){oJ.forEach((g)=>g(m));oJ.clear();kJ.forEach((g)=>g(m));kJ.clear();m.bindFramebuffer(eB.FRAMEBUFFER,null);lJ.forEach((g)=>g(m));jJ.forEach((i){i.m.useProgram(i.AC);rJ.values.forEach((g)=>g(i));mJ.forEach((g)=>g(i));i.gJ.forEach((g)=>g(i));sJ.forEach((g)=>g(i));i.hJ.forEach((g)=>g(i));i.sG();});nJ.forEach((g)=>g(m));}}IG( o, u, q, g){var i=new v.KI();for(int j=0;j<o.length;j++ ){i.BC(o[j]).ND(q);var l=i.HE(u);if(l<g.x)g.x=l;var k=i.length;if(k>g.y)g.y=k;}}class mC{var MB;var WB;var lB;var yB;var hB;var kB;}class oE{var x=0;var y=0;var YB;var XB;var MH=EG;var PH=CG;var OH=DG;var NH=FG;final KB=new rH();oE();factory oE.HI( g){var i=new oE()..KB.hD=GF*45.0..KB.rC=1.0..KB.qC=100.0..DD(g)..XF(g);return i;}nB( g){g.viewport(x,y,YB,XB);KB.aF();KB.SH();}iC( g){SC(g,KB.LD,MH);SC(g,KB.oB,PH);VD(g,KB.vB,OH);SC(g,KB.rD,NH);g.m.uniform1f(g.getUniformLocation("_Near"),KB.rC);g.m.uniform1f(g.getUniformLocation("_Far"),KB.qC);}SF()=>new RC()..nB=nB..gC=iC;DD( g){var i=UB.window.devicePixelRatio;YB=(i*g.clientWidth).round();XB=(i*g.clientHeight).round();x=0;y=0;g.width=YB;g.height=XB;KB..left=x.toDouble()..right=x.toDouble()+YB.toDouble()..top=y.toDouble()..bottom=y.toDouble()+XB.toDouble()..QF=false..aspectRatio=YB.toDouble()/XB.toDouble()..aF();}XF( g){var i=(j){DD(g);};return UB.Window.resizeEvent.forTarget(g).listen(i);}}JG({ radius: 1.0, subdivisionsAxis: 6, subdivisionsHeight: 6, startLatitudeInRadians: 0.0, endLatitudeInRadians: QD.PI, startLongitudeInRadians: 0.0, endLongitudeInRadians: 2*QD.PI}){if(subdivisionsAxis<=0||subdivisionsHeight<=0){throw new Exception('subdivisionAxis and subdivisionHeight must be > 0');}var qB=endLatitudeInRadians-startLatitudeInRadians;var rB=endLongitudeInRadians-startLongitudeInRadians;var u=(subdivisionsAxis+1)*(subdivisionsHeight+1);var q=new JC.Float32List(3*u);var o=new JC.Float32List(3*u);var AB=new JC.Float32List(2*u);for(var g=0,j=0;j<=subdivisionsHeight;j++ ){for(var i=0;i<=subdivisionsAxis;i++ ){var OB=i/subdivisionsAxis;var TB=j/subdivisionsHeight;var DB=rB*OB;var NB=qB*TB;var cB=QD.sin(DB);var sB=QD.cos(DB);var PB=QD.sin(NB);var dB=QD.cos(NB);var BB=sB*PB;var ZB=dB;var IB=cB*PB;q[g*3+0]=radius*BB;q[g*3+1]=radius*ZB;q[g*3+2]=radius*IB;o[g*3+0]=BB;o[g*3+1]=ZB;o[g*3+2]=IB;AB[g*2+0]=1-OB;AB[g*2+1]=TB;g++ ;}}var l=subdivisionsAxis+1;var k=new JC.Uint16List(3*subdivisionsAxis*subdivisionsHeight*2);for(var g=0,i=0;i<subdivisionsAxis;i++ ){for(var j=0;j<subdivisionsHeight;j++ ){k[g++ ]=(j+0)*l+i;k[g++ ]=(j+0)*l+i+1;k[g++ ]=(j+1)*l+i;k[g++ ]=(j+1)*l+i;k[g++ ]=(j+0)*l+i+1;k[g++ ]=(j+1)*l+i+1;}}return new mC()..MB=q..WB=o..lB=AB..hB=k;}class uH{var MD;var spacing=3;var jB=null;var length=0;setData( g, i){if(jB==null){jB=g.createBuffer();length=i.length;}else if(length!=i.length){g.deleteBuffer(jB);jB=g.createBuffer();length=i.length;}g.bindBuffer(eB.ARRAY_BUFFER,jB);g.bufferDataTyped(eB.ARRAY_BUFFER,i,eB.STATIC_DRAW);}kD( j){if(jB==null)return;var i=j.m;var g=j.getAttribLocation(MD);if(g==-1)return;i.bindBuffer(eB.ARRAY_BUFFER,jB);i.enableVertexAttribArray(g);i.vertexAttribPointer(g,spacing,eB.FLOAT,false,0,0);}}class pE{var x=0;var y=0;var YB;var XB;var qD=new LB.KI();pE();nB( g){g.viewport(x,y,YB,XB);qD.x=1.0/YB.toDouble();qD.y=1.0/XB.toDouble();}iC( g){g.m.uniform2f(g.getUniformLocation(GG),qD.x,qD.y);}SF()=>new RC()..nB=nB..gC=iC;DD( g){var i=UB.window.devicePixelRatio;YB=(i*g.clientWidth).round();XB=(i*g.clientHeight).round();x=0;y=0;g.width=YB;g.height=XB;}XF( g){var i=(j){DD(g);};return UB.Window.resizeEvent.forTarget(g).listen(i);}}class vH{var jB=null;var length=-1;setData( g, i){if(jB==null){jB=g.createBuffer();length=i.length;}else if(length!=i.length){g.deleteBuffer(jB);jB=g.createBuffer();length=i.length;}g.bindBuffer(eB.ELEMENT_ARRAY_BUFFER,jB);g.bufferDataTyped(eB.ELEMENT_ARRAY_BUFFER,i,eB.STATIC_DRAW);}drawElements( j, i){if(jB==null)return;var g=j.m;g.bindBuffer(eB.ELEMENT_ARRAY_BUFFER,jB);g.drawElements(i,length,eB.UNSIGNED_SHORT,0);}}typedef  UD( gl);typedef  QC( ctx);typedef  qE( pr, ctx);class RC{var GB=null;var nB=null;var BD=null;var gC=null;var fC=null;var eC=null;var AD=null;var at=null;var ZF=null;var bD=null;var nD=null;var oD=null;RC();}class wH{final  m;get buffer=>tJ;get VC=>uJ;var tJ;var vJ;var uJ;wH(this.m);ID({ width: -1, height: -1, type: eB.UNSIGNED_BYTE,hasDepthBuff: true}){KF();if(width<0)width=m.canvas.width;if(height<0)height=m.canvas.height;tJ=m.createFramebuffer();m.bindFramebuffer(eB.FRAMEBUFFER,tJ);uJ=m.createTexture();m.bindTexture(eB.TEXTURE_2D,uJ);m.texImage2DTyped(eB.TEXTURE_2D,0,eB.RGBA,width,height,0,eB.RGBA,type,null);m.texParameteri(eB.TEXTURE_2D,eB.TEXTURE_WRAP_S,eB.CLAMP_TO_EDGE);m.texParameteri(eB.TEXTURE_2D,eB.TEXTURE_WRAP_T,eB.CLAMP_TO_EDGE);m.texParameteri(eB.TEXTURE_2D,eB.TEXTURE_MAG_FILTER,eB.NEAREST);m.texParameteri(eB.TEXTURE_2D,eB.TEXTURE_MIN_FILTER,eB.NEAREST);m.framebufferTexture2D(eB.FRAMEBUFFER,eB.COLOR_ATTACHMENT0,eB.TEXTURE_2D,uJ,0);if(hasDepthBuff){vJ=m.createRenderbuffer();m.bindRenderbuffer(eB.RENDERBUFFER,vJ);m.renderbufferStorage(eB.RENDERBUFFER,eB.DEPTH_COMPONENT16,width,height);m.framebufferRenderbuffer(eB.FRAMEBUFFER,eB.DEPTH_ATTACHMENT,eB.RENDERBUFFER,vJ);}m.bindTexture(eB.TEXTURE_2D,null);m.bindRenderbuffer(eB.RENDERBUFFER,null);m.bindFramebuffer(eB.FRAMEBUFFER,null);}KF(){if(vJ!=null){m.deleteRenderbuffer(vJ);vJ=null;}if(uJ!=null){m.deleteTexture(uJ);uJ=null;}if(tJ==null){m.deleteFramebuffer(tJ);tJ=null;}}}rE( i, j, o){var g=i.createShader(o);i.shaderSource(g,j);i.compileShader(g);var k=(i.getShaderParameter(g,eB.COMPILE_STATUS).toString()=="true");if(!k){var l=i.getShaderInfoLog(g);i.deleteShader(g);g=null;throw new Exception("An error occurred compiling the shaders: ${k}: ${l}\n ${j} ");}return g;}KG( g, k, j,[l=true]){var i=g.createProgram();g.attachShader(i,k);g.attachShader(i,j);g.linkProgram(i);if(!g.getProgramParameter(i,eB.LINK_STATUS)){var o=g.getProgramInfoLog(i);g.detachShader(i,j);g.detachShader(i,k);if(l){g.deleteShader(k);g.deleteShader(j);}g.deleteProgram(i);i=null;throw new Exception("An error occurred compiling the shaders: ${o}");}return i;} SC( g, k, j){var i=g.getUniformLocation(j);if(i!=null){g.m.uniformMatrix4fv(i,false,k.h);}} VD( g, k, j){var i=g.getUniformLocation(j);if(i!=null){g.m.uniformMatrix3fv(i,false,k.h);}}WD( i, g){g.h[0]=i.h[0];g.h[1]=i.h[1];g.h[2]=i.h[2];g.h[3]=i.h[4];g.h[4]=i.h[5];g.h[5]=i.h[6];g.h[6]=i.h[8];g.h[7]=i.h[9];g.h[8]=i.h[10];return g..PF()..UE();} LG(j, i, k){return EB.Future.wait([UB.HttpRequest.request(i.toString(),method:'GET'),UB.HttpRequest.request(k.toString(),method:'GET')]).then((g)=>new bB(j,g[0].responseText,g[1].responseText));} MG( i, g,{importImgToTexture(RenderingContext,Texture,ImageElement): nE}){g.pB['tex2d']=new lH();g.pB['filter2d']=new bE();g.pB['shaderProgram']=new xH();g.zB['tex2d']=new zH(i,importImgToTexture);g.zB['filter2d']=new AI(i);g.zB['shaderProgram']=new yH(i);}final NG=new RegExp("""\{([A-Za-z_.0-9]*),([A-Za-z_.0-9]*)\}"""); OG( g){var k='.vert';var j='.frag';var i=NG.firstMatch(g);if(i!=null){var l=i.group(0);var k=i.group(1);var j=i.group(2);return [g.replaceFirst(l,k),g.replaceFirst(l,j)];}return [g+k,g+j];}class xH extends OC{ load( g, k){var i=new bE();var l=OG(g.url);var q=new t(g.KD,g.name,l[0],'vertexShader',i,null,null,null);var o=new t(g.KD,g.name,l[1],'fragmentShader',i,null,null,null);return EB.Future.wait([i.load(q,k),i.load(o,k)]).then((j){if(j[0]==null||j[1]==null)return null;return j;});} delete( g){}}class yH extends KC{final  m;yH(this.m); initialize( g){g.QB=null;}EB.Future<dynamic> import( g, l, o){if(g is List&&g.length==2){var k=g[0];var j=g[1];var i=new bB(m,k,j);l.QB=i;return new EB.Future.value(i);}return new EB.Future.value(null);} delete( g){if(g==null){return;}g.delete();}}class zH extends KC{final  m;final  NF;zH(this.m,this.NF(RenderingContext,Texture,ImageElement)); initialize( i){var g=m.createTexture();i.QB=g;}EB.Future<dynamic> import( i, g, j){print("imported import ${g.QB}");if(i is UB.ImageElement){if(g.QB==null){g.QB=m.createTexture();}NF(m,g.QB,i);return new EB.Future.value(g.QB);}return new EB.Future.value(g.QB);} delete( g){if(g==null){return;}m.deleteTexture(g);}}class AI extends KC{final  m;AI(this.m); initialize( g){g.QB=null;}EB.Future<dynamic> import( i, j, k){if(i is String){var g=new SD(m,i);j.QB=g;return new EB.Future.value(g);}return new EB.Future.value(null);} delete( g){if(g==null){return;}g.GB.delete();}}class BI{var RB;var JD;var EE;var JE;BI(this.RB,this.JD){EE=new RC()..GB=JD.GB..at=(g){if(JD.cfg!=null)JD.cfg(g);RB.jD(g);};JE=new RC()..AD=RB.jD;}}class PG{final m;final  wJ;final  xJ;var yJ;var zJ; get MF=>yJ.hC;set rG( g)=>zJ.tD=g;var AK;final BK;var CK;get dD=>AK;set dD( g)=>DK(g);var EK=new Map<BE,BI>();PG(g):this.m=g,wJ=new AE(g),xJ=new AE(g),BK=new wH(g);yC( g){wJ.register(g);}JH( g){wJ.unregister(g);}add( g){xJ.register(g);}remove( g){xJ.unregister(g);}HF( i, j){var g=new BI(i,j);EK[i]=g;yC(g.JE);add(g.EE);}YF( i){var g=EK[i];if(g!=null){JH(g.JE);remove(g.EE);EK[i]=null;}}var FK,GK,HK;GD(){GK=m.getExtension("OES_texture_float");IK();JK();KK();}DK(i){AK=i;BK.KF();BK.ID(width:i.YB,height:i.XB);if(CK!=null)remove(CK);CK=new RC()..nB=(g){if(true){g.disable(eB.BLEND);g.depthFunc(eB.LEQUAL);g.enable(eB.DEPTH_TEST);}g.colorMask(true,true,true,true);i.nB(g);}..BD=(g){g.bindFramebuffer(eB.FRAMEBUFFER,BK.buffer);g.viewport(i.x,i.y,i.YB,i.XB);g.clearColor(1.0,0.0,0.0,1.0);g.clear(eB.COLOR_BUFFER_BIT|eB.DEPTH_BUFFER_BIT);}..gC=i.iC;add(CK);yJ.tD=BK.VC;}KK(){}JK(){var i=new pE()..YB=256..XB=256..x=10..y=0;zJ=new mE(m,i);UB.HttpRequest.request('packages/glf/shaders/filters_2d/identity.frag',method:'GET').then((g){zJ.hC.add(new SD(m,g.responseText));});}IK(){var g=new pE()..DD(m.canvas);yJ=new mE(m,g);}run(){wJ.run();xJ.run();yJ.run();if(zJ.tD!=null)zJ.run();}}class BE{final WC=new CB.MI();final sC=new JB.KI();final lD=new sH();var LK=null;var LE=true;var VE=false;var TF=true;get mD=>LK;set mD( g){LK=g;LE=true;}jD( g){if(LE&&LK!=null){lD.setData(g.m,LK);LE=false;VE=false;}if(VE&&LK!=null){lD.MB.setData(g.m,LK.MB);VE=false;}if(TF){WD(WC,sC);TF=false;}SC(g,WC,lE);VD(g,sC,kE);lD.OF(g);lD.LF(g);}}class sE{var GB=null;var cfg=null;}final QG=r"""
(function() {
  // Proxy support for js.dart.

  var globalContext = window;

  // Support for binding the receiver (this) in proxied functions.
  function bindIfFunction(f, _this) {
    if (typeof(f) != "function") {
      return f;
    } else {
      return new BoundFunction(_this, f);
    }
  }

  function unbind(obj) {
    if (obj instanceof BoundFunction) {
      return obj.object;
    } else {
      return obj;
    }
  }

  function getBoundThis(obj) {
    if (obj instanceof BoundFunction) {
      return obj._this;
    } else {
      return globalContext;
    }
  }

  function BoundFunction(_this, object) {
    this._this = _this;
    this.object = object;
  }

  // Table for local objects and functions that are proxied.
  function ProxiedObjectTable() {
    // Name for debugging.
    this.name = 'js-ref';

    // Table from IDs to JS objects.
    this.map = {};

    // Generator for new IDs.
    this._nextId = 0;

    // Counter for deleted proxies.
    this._deletedCount = 0;

    // Flag for one-time initialization.
    this._initialized = false;

    // Ports for managing communication to proxies.
    this.port = new ReceivePortSync();
    this.sendPort = this.port.toSendPort();

    // Set of IDs that are global.
    // These will not be freed on an exitScope().
    this.globalIds = {};

    // Stack of scoped handles.
    this.handleStack = [];

    // Stack of active scopes where each value is represented by the size of
    // the handleStack at the beginning of the scope.  When an active scope
    // is popped, the handleStack is restored to where it was when the
    // scope was entered.
    this.scopeIndices = [];
  }

  // Number of valid IDs.  This is the number of objects (global and local)
  // kept alive by this table.
  ProxiedObjectTable.prototype.count = function () {
    return Object.keys(this.map).length;
  }

  // Number of total IDs ever allocated.
  ProxiedObjectTable.prototype.total = function () {
    return this.count() + this._deletedCount;
  }

  // Adds an object to the table and return an ID for serialization.
  ProxiedObjectTable.prototype.add = function (obj) {
    if (this.scopeIndices.length == 0) {
      throw "Cannot allocate a proxy outside of a scope.";
    }
    // TODO(vsm): Cache refs for each obj?
    var ref = this.name + '-' + this._nextId++;
    this.handleStack.push(ref);
    this.map[ref] = obj;
    return ref;
  }

  ProxiedObjectTable.prototype._initializeOnce = function () {
    if (!this._initialized) {
      this._initialize();
      this._initialized = true;
    }
  }

  // Enters a new scope for this table.
  ProxiedObjectTable.prototype.enterScope = function() {
    this._initializeOnce();
    this.scopeIndices.push(this.handleStack.length);
  }

  // Invalidates all non-global IDs in the current scope and
  // exit the current scope.
  ProxiedObjectTable.prototype.exitScope = function() {
    var start = this.scopeIndices.pop();
    for (var i = start; i < this.handleStack.length; ++i) {
      var key = this.handleStack[i];
      if (!this.globalIds.hasOwnProperty(key)) {
        delete this.map[this.handleStack[i]];
        this._deletedCount++;
      }
    }
    this.handleStack = this.handleStack.splice(0, start);
  }

  // Makes this ID globally scope.  It must be explicitly invalidated.
  ProxiedObjectTable.prototype.globalize = function(id) {
    this.globalIds[id] = true;
  }

  // Invalidates this ID, potentially freeing its corresponding object.
  ProxiedObjectTable.prototype.invalidate = function(id) {
    var old = this.get(id);
    delete this.globalIds[id];
    delete this.map[id];
    this._deletedCount++;
  }

  // Gets the object or function corresponding to this ID.
  ProxiedObjectTable.prototype.get = function (id) {
    if (!this.map.hasOwnProperty(id)) {
      throw 'Proxy ' + id + ' has been invalidated.'
    }
    return this.map[id];
  }

  ProxiedObjectTable.prototype._initialize = function () {
    // Configure this table's port to forward methods, getters, and setters
    // from the remote proxy to the local object.
    var table = this;

    this.port.receive(function (message) {
      // TODO(vsm): Support a mechanism to register a handler here.
      try {
        var object = table.get(message[0]);
        var receiver = unbind(object);
        var member = message[1];
        var kind = message[2];
        var args = message[3].map(deserialize);
        if (kind == 'get') {
          // Getter.
          var field = member;
          if (field in receiver && args.length == 0) {
            var result = bindIfFunction(receiver[field], receiver);
            return [ 'return', serialize(result) ];
          }
        } else if (kind == 'set') {
          // Setter.
          var field = member;
          if (args.length == 1) {
            return [ 'return', serialize(receiver[field] = args[0]) ];
          }
        } else if (kind == 'apply') {
          // Direct function invocation.
          var _this = getBoundThis(object);
          return [ 'return', serialize(receiver.apply(_this, args)) ];
        } else if (member == '[]' && args.length == 1) {
          // Index getter.
          var result = bindIfFunction(receiver[args[0]], receiver);
          return [ 'return', serialize(result) ];
        } else if (member == '[]=' && args.length == 2) {
          // Index setter.
          return [ 'return', serialize(receiver[args[0]] = args[1]) ];
        } else {
          // Member function invocation.
          var f = receiver[member];
          if (f) {
            var result = f.apply(receiver, args);
            return [ 'return', serialize(result) ];
          }
        }
        return [ 'none' ];
      } catch (e) {
        return [ 'throws', e.toString() ];
      }
    });
  }

  // Singleton for local proxied objects.
  var proxiedObjectTable = new ProxiedObjectTable();

  // DOM element serialization code.
  var _localNextElementId = 0;
  var _DART_ID = 'data-dart_id';
  var _DART_TEMPORARY_ATTACHED = 'data-dart_temporary_attached';

  function serializeElement(e) {
    // TODO(vsm): Use an isolate-specific id.
    var id;
    if (e.hasAttribute(_DART_ID)) {
      id = e.getAttribute(_DART_ID);
    } else {
      id = (_localNextElementId++).toString();
      e.setAttribute(_DART_ID, id);
    }
    if (e !== document.documentElement) {
      // Element must be attached to DOM to be retrieve in js part.
      // Attach top unattached parent to avoid detaching parent of "e" when
      // appending "e" directly to document. We keep count of elements
      // temporarily attached to prevent detaching top unattached parent to
      // early. This count is equals to the length of _DART_TEMPORARY_ATTACHED
      // attribute. There could be other elements to serialize having the same
      // top unattached parent.
      var top = e;
      while (true) {
        if (top.hasAttribute(_DART_TEMPORARY_ATTACHED)) {
          var oldValue = top.getAttribute(_DART_TEMPORARY_ATTACHED);
          var newValue = oldValue + "a";
          top.setAttribute(_DART_TEMPORARY_ATTACHED, newValue);
          break;
        }
        if (top.parentNode == null) {
          top.setAttribute(_DART_TEMPORARY_ATTACHED, "a");
          document.documentElement.appendChild(top);
          break;
        }
        if (top.parentNode === document.documentElement) {
          // e was already attached to dom
          break;
        }
        top = top.parentNode;
      }
    }
    return id;
  }

  function deserializeElement(id) {
    // TODO(vsm): Clear the attribute.
    var list = document.querySelectorAll('[' + _DART_ID + '="' + id + '"]');

    if (list.length > 1) throw 'Non unique ID: ' + id;
    if (list.length == 0) {
      throw 'Element must be attached to the document: ' + id;
    }
    var e = list[0];
    if (e !== document.documentElement) {
      // detach temporary attached element
      var top = e;
      while (true) {
        if (top.hasAttribute(_DART_TEMPORARY_ATTACHED)) {
          var oldValue = top.getAttribute(_DART_TEMPORARY_ATTACHED);
          var newValue = oldValue.substring(1);
          top.setAttribute(_DART_TEMPORARY_ATTACHED, newValue);
          // detach top only if no more elements have to be unserialized
          if (top.getAttribute(_DART_TEMPORARY_ATTACHED).length === 0) {
            top.removeAttribute(_DART_TEMPORARY_ATTACHED);
            document.documentElement.removeChild(top);
          }
          break;
        }
        if (top.parentNode === document.documentElement) {
          // e was already attached to dom
          break;
        }
        top = top.parentNode;
      }
    }
    return e;
  }


  // Type for remote proxies to Dart objects.
  function DartProxy(id, sendPort) {
    this.id = id;
    this.port = sendPort;
  }

  // Serializes JS types to SendPortSync format:
  // - primitives -> primitives
  // - sendport -> sendport
  // - DOM element -> [ 'domref', element-id ]
  // - Function -> [ 'funcref', function-id, sendport ]
  // - Object -> [ 'objref', object-id, sendport ]
  function serialize(message) {
    if (message == null) {
      return null;  // Convert undefined to null.
    } else if (typeof(message) == 'string' ||
               typeof(message) == 'number' ||
               typeof(message) == 'boolean') {
      // Primitives are passed directly through.
      return message;
    } else if (message instanceof SendPortSync) {
      // Non-proxied objects are serialized.
      return message;
    } else if (message instanceof Element &&
        (message.ownerDocument == null || message.ownerDocument == document)) {
      return [ 'domref', serializeElement(message) ];
    } else if (message instanceof BoundFunction &&
               typeof(message.object) == 'function') {
      // Local function proxy.
      return [ 'funcref',
               proxiedObjectTable.add(message),
               proxiedObjectTable.sendPort ];
    } else if (typeof(message) == 'function') {
      if ('_dart_id' in message) {
        // Remote function proxy.
        var remoteId = message._dart_id;
        var remoteSendPort = message._dart_port;
        return [ 'funcref', remoteId, remoteSendPort ];
      } else {
        // Local function proxy.
        return [ 'funcref',
                 proxiedObjectTable.add(message),
                 proxiedObjectTable.sendPort ];
      }
    } else if (message instanceof DartProxy) {
      // Remote object proxy.
      return [ 'objref', message.id, message.port ];
    } else {
      // Local object proxy.
      return [ 'objref',
               proxiedObjectTable.add(message),
               proxiedObjectTable.sendPort ];
    }
  }

  function deserialize(message) {
    if (message == null) {
      return null;  // Convert undefined to null.
    } else if (typeof(message) == 'string' ||
               typeof(message) == 'number' ||
               typeof(message) == 'boolean') {
      // Primitives are passed directly through.
      return message;
    } else if (message instanceof SendPortSync) {
      // Serialized type.
      return message;
    }
    var tag = message[0];
    switch (tag) {
      case 'funcref': return deserializeFunction(message);
      case 'objref': return deserializeObject(message);
      case 'domref': return deserializeElement(message[1]);
    }
    throw 'Unsupported serialized data: ' + message;
  }

  // Create a local function that forwards to the remote function.
  function deserializeFunction(message) {
    var id = message[1];
    var port = message[2];
    // TODO(vsm): Add a more robust check for a local SendPortSync.
    if ("receivePort" in port) {
      // Local function.
      return unbind(proxiedObjectTable.get(id));
    } else {
      // Remote function.  Forward to its port.
      var f = function () {
        var depth = enterScope();
        try {
          var args = Array.prototype.slice.apply(arguments);
          args.splice(0, 0, this);
          args = args.map(serialize);
          var result = port.callSync([id, '#call', args]);
          if (result[0] == 'throws') throw deserialize(result[1]);
          return deserialize(result[1]);
        } finally {
          exitScope(depth);
        }
      };
      // Cache the remote id and port.
      f._dart_id = id;
      f._dart_port = port;
      return f;
    }
  }

  // Creates a DartProxy to forwards to the remote object.
  function deserializeObject(message) {
    var id = message[1];
    var port = message[2];
    // TODO(vsm): Add a more robust check for a local SendPortSync.
    if ("receivePort" in port) {
      // Local object.
      return proxiedObjectTable.get(id);
    } else {
      // Remote object.
      return new DartProxy(id, port);
    }
  }

  // Remote handler to construct a new JavaScript object given its
  // serialized constructor and arguments.
  function construct(args) {
    args = args.map(deserialize);
    var constructor = unbind(args[0]);
    args = Array.prototype.slice.call(args, 1);

    // Until 10 args, the 'new' operator is used. With more arguments we use a
    // generic way that may not work, particulary when the constructor does not
    // have an "apply" method.
    var ret = null;
    if (args.length === 0) {
      ret = new constructor();
    } else if (args.length === 1) {
      ret = new constructor(args[0]);
    } else if (args.length === 2) {
      ret = new constructor(args[0], args[1]);
    } else if (args.length === 3) {
      ret = new constructor(args[0], args[1], args[2]);
    } else if (args.length === 4) {
      ret = new constructor(args[0], args[1], args[2], args[3]);
    } else if (args.length === 5) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4]);
    } else if (args.length === 6) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5]);
    } else if (args.length === 7) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6]);
    } else if (args.length === 8) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6], args[7]);
    } else if (args.length === 9) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6], args[7], args[8]);
    } else if (args.length === 10) {
      ret = new constructor(args[0], args[1], args[2], args[3], args[4],
                            args[5], args[6], args[7], args[8], args[9]);
    } else {
      // Dummy Type with correct constructor.
      var Type = function(){};
      Type.prototype = constructor.prototype;
  
      // Create a new instance
      var instance = new Type();
  
      // Call the original constructor.
      ret = constructor.apply(instance, args);
      ret = Object(ret) === ret ? ret : instance;
    }
    return serialize(ret);
  }

  // Remote handler to return the top-level JavaScript context.
  function context(data) {
    return serialize(globalContext);
  }

  // Remote handler to track number of live / allocated proxies.
  function proxyCount() {
    var live = proxiedObjectTable.count();
    var total = proxiedObjectTable.total();
    return [live, total];
  }

  // Return true if two JavaScript proxies are equal (==).
  function proxyEquals(args) {
    return deserialize(args[0]) == deserialize(args[1]);
  }

  // Return true if a JavaScript proxy is instance of a given type (instanceof).
  function proxyInstanceof(args) {
    var obj = unbind(deserialize(args[0]));
    var type = unbind(deserialize(args[1]));
    return obj instanceof type;
  }

  // Return true if a JavaScript proxy has a given property.
  function proxyHasProperty(args) {
    var obj = unbind(deserialize(args[0]));
    var member = unbind(deserialize(args[1]));
    return member in obj;
  }

  // Delete a given property of object.
  function proxyDeleteProperty(args) {
    var obj = unbind(deserialize(args[0]));
    var member = unbind(deserialize(args[1]));
    delete obj[member];
  }

  function proxyConvert(args) {
    return serialize(deserializeDataTree(args));
  }

  function deserializeDataTree(data) {
    var type = data[0];
    var value = data[1];
    if (type === 'map') {
      var obj = {};
      for (var i = 0; i < value.length; i++) {
        obj[value[i][0]] = deserializeDataTree(value[i][1]);
      }
      return obj;
    } else if (type === 'list') {
      var list = [];
      for (var i = 0; i < value.length; i++) {
        list.push(deserializeDataTree(value[i]));
      }
      return list;
    } else /* 'simple' */ {
      return deserialize(value);
    }
  }

  function makeGlobalPort(name, f) {
    var port = new ReceivePortSync();
    port.receive(f);
    window.registerPort(name, port.toSendPort());
  }

  // Enters a new scope in the JavaScript context.
  function enterJavaScriptScope() {
    proxiedObjectTable.enterScope();
  }

  // Enters a new scope in both the JavaScript and Dart context.
  var _dartEnterScopePort = null;
  function enterScope() {
    enterJavaScriptScope();
    if (!_dartEnterScopePort) {
      _dartEnterScopePort = window.lookupPort('js-dart-interop-enter-scope');
    }
    return _dartEnterScopePort.callSync([]);
  }

  // Exits the current scope (and invalidate local IDs) in the JavaScript
  // context.
  function exitJavaScriptScope() {
    proxiedObjectTable.exitScope();
  }

  // Exits the current scope in both the JavaScript and Dart context.
  var _dartExitScopePort = null;
  function exitScope(depth) {
    exitJavaScriptScope();
    if (!_dartExitScopePort) {
      _dartExitScopePort = window.lookupPort('js-dart-interop-exit-scope');
    }
    return _dartExitScopePort.callSync([ depth ]);
  }

  makeGlobalPort('dart-js-interop-context', context);
  makeGlobalPort('dart-js-interop-create', construct);
  makeGlobalPort('dart-js-interop-proxy-count', proxyCount);
  makeGlobalPort('dart-js-interop-equals', proxyEquals);
  makeGlobalPort('dart-js-interop-instanceof', proxyInstanceof);
  makeGlobalPort('dart-js-interop-has-property', proxyHasProperty);
  makeGlobalPort('dart-js-interop-delete-property', proxyDeleteProperty);
  makeGlobalPort('dart-js-interop-convert', proxyConvert);
  makeGlobalPort('dart-js-interop-enter-scope', enterJavaScriptScope);
  makeGlobalPort('dart-js-interop-exit-scope', exitJavaScriptScope);
  makeGlobalPort('dart-js-interop-globalize', function(data) {
    if (data[0] == "objref" || data[0] == "funcref") return proxiedObjectTable.globalize(data[1]);
    throw 'Illegal type: ' + data[0];
  });
  makeGlobalPort('dart-js-interop-invalidate', function(data) {
    if (data[0] == "objref" || data[0] == "funcref") return proxiedObjectTable.invalidate(data[1]);
    throw 'Illegal type: ' + data[0];
  });
})();
"""; RG(i){final g=new UB.ScriptElement();g.type='text/javascript';g.innerHtml=i;UB.document.body.nodes.add(g);}var vC=null;var SG=null;var TG=null;var tE=null;var UG=null;var VG=null;var WG=null;var uE=null;var vE=null;var wE=null;var xE=null;var XG=null;var yE=null;var zE=null; YG(){if(vC!=null)return;try {vC=UB.window.lookupPort('dart-js-interop-context');}catch (i){}if(vC==null){RG(QG);vC=UB.window.lookupPort('dart-js-interop-context');}SG=UB.window.lookupPort('dart-js-interop-create');TG=UB.window.lookupPort('dart-js-interop-proxy-count');tE=UB.window.lookupPort('dart-js-interop-equals');UG=UB.window.lookupPort('dart-js-interop-instanceof');VG=UB.window.lookupPort('dart-js-interop-has-property');WG=UB.window.lookupPort('dart-js-interop-delete-property');uE=UB.window.lookupPort('dart-js-interop-convert');vE=UB.window.lookupPort('dart-js-interop-enter-scope');wE=UB.window.lookupPort('dart-js-interop-exit-scope');xE=UB.window.lookupPort('dart-js-interop-globalize');XG=UB.window.lookupPort('dart-js-interop-invalidate');yE=new UB.ReceivePortSync()..receive((MK)=>BF());zE=new UB.ReceivePortSync()..receive((g)=>CF(g[0]));UB.window.registerPort('js-dart-interop-enter-scope',yE.toSendPort());UB.window.registerPort('js-dart-interop-exit-scope',zE.toSendPort());} get AF{XD();return xC(vC.callSync([] ));}get ZG=>tB.NK.length; XD(){if(ZG==0){var g=BF();EB.runAsync(()=>CF(g));}} BF(){YG();tB.vG();vE.callSync([] );return tB.NK.length;} CF( g){assert(tB.NK.length==g);wE.callSync([] );tB.wG();} DF( g){xE.callSync(bC(g.SE()));return g;} EF( g)=>new xB.II(g);class CI{const CI();}const aC=const CI(); aG(j,o,l,k,u,q){final g=[j,o,l,k,u,q];final i=g.indexOf(aC);if(i<0)return g;return g.sublist(0,i);}class xB implements YD<xB>{var OK;final PK;factory xB.II(g){XD();return bG(g);}static bG(g){return xC(uE.callSync(CE(g)));}static CE(g){if(g is Map){final i=new List();for(var j in g.keys){i.add([j,CE(g[j])]);}return ['map',i];}else if(g is Iterable){return ['list',g.map(CE).toList()];}else{return ['simple',bC(g)];}}xB.JI(this.OK,this.PK); SE()=>this;operator[](g)=>wC(this,'[]','method',[g]);operator[]=(i,g)=>wC(this,'[]=','method',[i,g]);operator==(g)=>identical(this,g)?true:(g is xB&&tE.callSync([bC(this),bC(g)])); toString(){try {return wC(this,'toString','method',[] );}catch (g){return super.toString();}}noSuchMethod( j){var g=TH.MirrorSystem.getName(j.memberName);if(g.indexOf('@')!=-1){g=g.substring(0,g.indexOf('@'));}var i;var k=j.positionalArguments;if(k==null)k=[] ;if(j.isGetter){i='get';}else if(j.isSetter){i='set';if(g.endsWith('=')){g=g.substring(0,g.length-1);}}else if(g=='call'){i='apply';}else{i='method';}return wC(this,g,i,k);}static wC( g, j, l, k){XD();var i=g.OK.callSync([g.PK,j,l,k.map(bC).toList()]);switch (i[0]){case 'return':return xC(i[1]);case 'throws':throw xC(i[1]);case 'none':throw new NoSuchMethodError(g,j,k,{});default:throw 'Invalid return value';}}}class FF extends xB implements YD<FF>{FF.JI( i,g):super.JI(i,g);call([g=aC,k=aC,j=aC,i=aC,q=aC,l=aC]){var o=aG(g,k,j,i,q,l);return xB.wC(this,'','apply',o);}}abstract class YD<cG>{ SE();}class dG{final  QK;var RK;var SK;final  TK;final  OK;final  UK;final  VK;final  NK;vG(){NK.add(VK.length);}wG(){var i=NK.removeLast();for(int g=i;g<VK.length; ++g){var j=VK[g];if(!UK.contains(j)){TK.remove(VK[g]);SK++ ;}}if(i!=VK.length){VK.removeRange(i,VK.length-i);}}dG():QK='dart-ref',RK=0,SK=0,TK={},OK=new UB.ReceivePortSync(),VK=new List<String>(),NK=new List<int>(),UK=new Set<String>(){OK.receive((g){try {final i=TK[g[0]];final l=g[1];final k=g[2].map(xC).toList();if(l=='#call'){final o=i as Function;var q=bC(o(k));return ['return',q];}else{throw 'Invocation unsupported on non-function Dart proxies';}}catch (j){return ['throws','${j}'];}});} add(i){XD();final g='${QK}-${RK++ }';TK[g]=i;VK.add(g);return g;}Object get( g){return TK[g];}get count=>TK.length;get total=>count+SK;get RE=>OK.toSendPort();}var tB=new dG();bC(var g){if(g==null){return null;}else if(g is String||g is num||g is bool){return g;}else if(g is iB.SendPortSync){return g;}else if(g is UB.Element&&(g.document==null||g.document==UB.document)){return ['domref',fG(g)];}else if(g is FF){return ['funcref',g.PK,g.OK];}else if(g is xB){return ['objref',g.PK,g.OK];}else if(g is YD){return bC(g.SE());}else{return ['objref',tB.add(g),tB.RE];}}xC(var g){o(g){var i=g[1];var j=g[2];if(j==tB.RE){return tB.get(i);}else{return new FF.JI(j,i);}}l(g){var i=g[1];var j=g[2];if(j==tB.RE){return tB.get(i);}else{return new xB.JI(j,i);}}if(g==null){return null;}else if(g is String||g is num||g is bool){return g;}else if(g is iB.SendPortSync){return g;}var k=g[0];switch (k){case 'funcref':return o(g);case 'objref':return l(g);case 'domref':return gG(g[1]);}throw 'Unsupported serialized data: ${g}';}var eG=0;const ZD='data-dart_id';const LC='data-dart_temporary_attached';fG( i){var j;if(i.attributes.containsKey(ZD)){j=i.attributes[ZD];}else{j='dart-${eG++ }';i.attributes[ZD]=j;}if(!identical(i,UB.document.documentElement)){var g=i;while (true){if(g.attributes.containsKey(LC)){final k=g.attributes[LC];final l=k+'a';g.attributes[LC]=l;break;}if(g.parent==null){g.attributes[LC]='a';UB.document.documentElement.children.add(g);break;}if(identical(g.parent,UB.document.documentElement)){break;}g=g.parent;}}return j;} gG(var j){var k=UB.queryAll('[${ZD}="${j}"]');if(k.length>1)throw 'Non unique ID: ${j}';if(k.length==0){throw 'Only elements attached to document can be serialized: ${j}';}final i=k[0];if(!identical(i,UB.document.documentElement)){var g=i;while (true){if(g.attributes.containsKey(LC)){final l=g.attributes[LC];final o=l.substring(1);g.attributes[LC]=o;if(g.attributes[LC].length==0){g.attributes.remove(LC);g.remove();}break;}if(identical(g.parent,UB.document.documentElement)){break;}g=g.parent;}}return i;}const  GF=QD.PI/180.0;class aD{final  WK;final  XK; get min=>WK; get max=>XK;aD():WK=new v.KI(),XK=new v.KI(){} pC( g){g.WK.BC(WK);g.XK.BC(XK);} contains( g){return min.x<g.min.x&&min.y<g.min.y&&min.z<g.min.z&&max.x>g.max.x&&max.y>g.max.y&&max.z>g.max.z;}}class FB{final  h=new JC.Float32List(4);FB( k, i, g, j){wB(k,i,g,j);}FB.KI();FB.LI( g){BC(g);} wB( k, i, g, j){h[3]=j;h[2]=g;h[1]=i;h[0]=k;return this;} kC(){h[0]=0.0;h[1]=0.0;h[2]=0.0;h[3]=0.0;return this;} BC( g){h[3]=g.h[3];h[2]=g.h[2];h[1]=g.h[1];h[0]=g.h[0];return this;} toString()=>'${h[0]},${h[1]},' '${h[2]},${h[3]}'; operator-()=>new FB(-h[0],-h[1],-h[2],-h[3]); operator-( g)=>new FB(h[0]-g.h[0],h[1]-g.h[1],h[2]-g.h[2],h[3]-g.h[3]); operator+( g)=>new FB(h[0]+g.h[0],h[1]+g.h[1],h[2]+g.h[2],h[3]+g.h[3]); operator/( i){var g=1.0/i;return new FB(h[0]*g,h[1]*g,h[2]*g,h[3]*g);} operator*( i){var g=i;return new FB(h[0]*g,h[1]*g,h[2]*g,h[3]*g);} operator[]( g)=>h[g]; operator[]=( i, g){h[i]=g;} get length{var g;g=(h[0]*h[0]);g+= (h[1]*h[1]);g+= (h[2]*h[2]);g+= (h[3]*h[3]);return QD.sqrt(g);} normalize(){var g=length;if(g==0.0){return this;}g=1.0/g;h[0]*=g;h[1]*=g;h[2]*=g;h[3]*=g;return this;} NE(){return new FB.LI(this).normalize();} HE( i){var g;g=h[0]*i.h[0];g+= h[1]*i.h[1];g+= h[2]*i.h[2];g+= h[3]*i.h[3];return g;} get isNaN{var g=false;g=g||h[0].isNaN;g=g||h[1].isNaN;g=g||h[2].isNaN;g=g||h[3].isNaN;return g;} add( g){h[0]=h[0]+g.h[0];h[1]=h[1]+g.h[1];h[2]=h[2]+g.h[2];h[3]=h[3]+g.h[3];return this;} ND( g){h[0]=h[0]-g.h[0];h[1]=h[1]-g.h[1];h[2]=h[2]-g.h[2];h[3]=h[3]-g.h[3];return this;} multiply( g){h[0]=h[0]*g.h[0];h[1]=h[1]*g.h[1];h[2]=h[2]*g.h[2];h[3]=h[3]*g.h[3];return this;} pC( g){g.h[0]=h[0];g.h[1]=h[1];g.h[2]=h[2];g.h[3]=h[3];return g;}set x( g)=>h[0]=g;set y( g)=>h[1]=g; get x=>h[0]; get y=>h[1]; get z=>h[2];}class LB{final  h=new JC.Float32List(2);LB( i, g){wB(i,g);}LB.KI();LB.LI( g){BC(g);} wB( i, g){h[0]=i;h[1]=g;return this;} kC(){h[0]=0.0;h[1]=0.0;return this;} BC( g){h[1]=g.h[1];h[0]=g.h[0];return this;} toString()=>'[${h[0]},${h[1]}]'; operator-()=>new LB(-h[0],-h[1]); operator-( g)=>new LB(h[0]-g.h[0],h[1]-g.h[1]); operator+( g)=>new LB(h[0]+g.h[0],h[1]+g.h[1]); operator/( i){var g=1.0/i;return new LB(h[0]*g,h[1]*g);} operator*( i){var g=i;return new LB(h[0]*g,h[1]*g);} operator[]( g)=>h[g]; operator[]=( i, g){h[i]=g;} get length{var g;g=(h[0]*h[0]);g+= (h[1]*h[1]);return QD.sqrt(g);} normalize(){var g=length;if(g==0.0){return this;}g=1.0/g;h[0]*=g;h[1]*=g;return this;} NE(){return new LB.LI(this).normalize();} HE( i){var g;g=h[0]*i.h[0];g+= h[1]*i.h[1];return g;} FE( g){return h[0]*g.h[1]-h[1]*g.h[0];} get isNaN{var g=false;g=g||h[0].isNaN;g=g||h[1].isNaN;return g;} add( g){h[0]=h[0]+g.h[0];h[1]=h[1]+g.h[1];return this;} ND( g){h[0]=h[0]-g.h[0];h[1]=h[1]-g.h[1];return this;} multiply( g){h[0]=h[0]*g.h[0];h[1]=h[1]*g.h[1];return this;} pC( g){g.h[1]=h[1];g.h[0]=h[0];return g;}set x( g)=>h[0]=g;set y( g)=>h[1]=g; get x=>h[0]; get y=>h[1];}class v{final  h=new JC.Float32List(3);v( j, i, g){wB(j,i,g);}v.KI();v.LI( g){BC(g);} wB( j, i, g){h[0]=j;h[1]=i;h[2]=g;return this;} kC(){h[2]=0.0;h[1]=0.0;h[0]=0.0;return this;} BC( g){h[0]=g.h[0];h[1]=g.h[1];h[2]=g.h[2];return this;} toString()=>'[${h[0]},${h[1]},${h[2]}]'; operator-()=>new v(-h[0],-h[1],-h[2]); operator-( g)=>new v(h[0]-g.h[0],h[1]-g.h[1],h[2]-g.h[2]); operator+( g)=>new v(h[0]+g.h[0],h[1]+g.h[1],h[2]+g.h[2]); operator/( i){var g=1.0/i;return new v(h[0]*g,h[1]*g,h[2]*g);} operator*( i){var g=i;return new v(h[0]*g,h[1]*g,h[2]*g);} operator[]( g)=>h[g]; operator[]=( i, g){h[i]=g;} get length{var g;g=(h[0]*h[0]);g+= (h[1]*h[1]);g+= (h[2]*h[2]);return QD.sqrt(g);} normalize(){var g=length;if(g==0.0){return this;}g=1.0/g;h[0]*=g;h[1]*=g;h[2]*=g;return this;} NE(){return new v.LI(this).normalize();} HE( i){var g;g=h[0]*i.h[0];g+= h[1]*i.h[1];g+= h[2]*i.h[2];return g;} FE( g){var YK=h[0];var ZK=h[1];var aK=h[2];var i=g.h[0];var k=g.h[1];var j=g.h[2];return new v(ZK*j-aK*k,aK*i-YK*j,YK*k-ZK*i);} get isNaN{var g=false;g=g||h[0].isNaN;g=g||h[1].isNaN;g=g||h[2].isNaN;return g;} add( g){h[0]=h[0]+g.h[0];h[1]=h[1]+g.h[1];h[2]=h[2]+g.h[2];return this;} ND( g){h[0]=h[0]-g.h[0];h[1]=h[1]-g.h[1];h[2]=h[2]-g.h[2];return this;} multiply( g){h[0]=h[0]*g.h[0];h[1]=h[1]*g.h[1];h[2]=h[2]*g.h[2];return this;} pC( g){g.h[0]=h[0];g.h[1]=h[1];g.h[2]=h[2];return g;}set x( g)=>h[0]=g;set y( g)=>h[1]=g; get x=>h[0]; get y=>h[1]; get z=>h[2];}const  hG=180.0/QD.PI;class JB{final  h=new JC.Float32List(9); index( g, i)=>(i*3)+g; entry( g, i)=>h[index(g,i)];HB( g, i, j){h[index(g,i)]=j;}JB.KI();JB.MI(){sD();} BC( g){h[8]=g.h[8];h[7]=g.h[7];h[6]=g.h[6];h[5]=g.h[5];h[4]=g.h[4];h[3]=g.h[3];h[2]=g.h[2];h[1]=g.h[1];h[0]=g.h[0];return this;} toString(){var g='';g='${g}[0] ${TC(0)}\n';g='${g}[1] ${TC(1)}\n';g='${g}[2] ${TC(2)}\n';return g;} get GE=>3; operator[]( g)=>h[g]; operator[]=( i, g){h[i]=g;} TC( i){var g=new v.KI();g.h[0]=h[index(i,0)];g.h[1]=h[index(i,1)];g.h[2]=h[index(i,2)];return g;} pC( g){g.h[0]=h[0];g.h[1]=h[1];g.h[2]=h[2];g.h[3]=h[3];g.h[4]=h[4];g.h[5]=h[5];g.h[6]=h[6];g.h[7]=h[7];g.h[8]=h[8];return g;} bK( i){var g=new JB.KI();g.h[8]=h[8]*i;g.h[7]=h[7]*i;g.h[6]=h[6]*i;g.h[5]=h[5]*i;g.h[4]=h[4]*i;g.h[3]=h[3]*i;g.h[2]=h[2]*i;g.h[1]=h[1]*i;g.h[0]=h[0]*i;return g;} cK( g){var i=new JB.KI();i.h[0]=(h[0]*g.h[0])+(h[3]*g.h[1])+(h[6]*g.h[2]);i.h[3]=(h[0]*g.h[3])+(h[3]*g.h[4])+(h[6]*g.h[5]);i.h[6]=(h[0]*g.h[6])+(h[3]*g.h[7])+(h[6]*g.h[8]);i.h[1]=(h[1]*g.h[0])+(h[4]*g.h[1])+(h[7]*g.h[2]);i.h[4]=(h[1]*g.h[3])+(h[4]*g.h[4])+(h[7]*g.h[5]);i.h[7]=(h[1]*g.h[6])+(h[4]*g.h[7])+(h[7]*g.h[8]);i.h[2]=(h[2]*g.h[0])+(h[5]*g.h[1])+(h[8]*g.h[2]);i.h[5]=(h[2]*g.h[3])+(h[5]*g.h[4])+(h[8]*g.h[5]);i.h[8]=(h[2]*g.h[6])+(h[5]*g.h[7])+(h[8]*g.h[8]);return i;} dK( g){var i=new v.KI();i.h[2]=(h[2]*g.h[0])+(h[5]*g.h[1])+(h[8]*g.h[2]);i.h[1]=(h[1]*g.h[0])+(h[4]*g.h[1])+(h[7]*g.h[2]);i.h[0]=(h[0]*g.h[0])+(h[3]*g.h[1])+(h[6]*g.h[2]);return i;} operator*( g){if(g is double){return bK(g);}if(g is v){return dK(g);}if(3==g.GE){return cK(g);}throw new ArgumentError(g);} operator+( i){var g=new JB.KI();g.h[0]=h[0]+i.h[0];g.h[1]=h[1]+i.h[1];g.h[2]=h[2]+i.h[2];g.h[3]=h[3]+i.h[3];g.h[4]=h[4]+i.h[4];g.h[5]=h[5]+i.h[5];g.h[6]=h[6]+i.h[6];g.h[7]=h[7]+i.h[7];g.h[8]=h[8]+i.h[8];return g;} operator-( i){var g=new JB.KI();g.h[0]=h[0]-i.h[0];g.h[1]=h[1]-i.h[1];g.h[2]=h[2]-i.h[2];g.h[3]=h[3]-i.h[3];g.h[4]=h[4]-i.h[4];g.h[5]=h[5]-i.h[5];g.h[6]=h[6]-i.h[6];g.h[7]=h[7]-i.h[7];g.h[8]=h[8]-i.h[8];return g;} operator-(){var g=new JB.KI();g[0]=-h[0];g[1]=-h[1];g[2]=-h[2];return g;} kC(){h[0]=0.0;h[1]=0.0;h[2]=0.0;h[3]=0.0;h[4]=0.0;h[5]=0.0;h[6]=0.0;h[7]=0.0;h[8]=0.0;return this;} sD(){h[0]=1.0;h[1]=0.0;h[2]=0.0;h[3]=0.0;h[4]=1.0;h[5]=0.0;h[6]=0.0;h[7]=0.0;h[8]=1.0;return this;} UE(){var g;g=h[3];h[3]=h[1];h[1]=g;g=h[6];h[6]=h[2];h[2]=g;g=h[7];h[7]=h[5];h[5]=g;return this;} JF(){var i=h[0]*((h[4]*h[8])-(h[5]*h[7]));var g=h[1]*((h[3]*h[8])-(h[5]*h[6]));var j=h[2]*((h[3]*h[7])-(h[4]*h[6]));return i-g+j;} PF(){var i=JF();if(i==0.0){return 0.0;}var g=1.0/i;var DB=g*(h[4]*h[8]-h[5]*h[7]);var u=g*(h[2]*h[7]-h[1]*h[8]);var l=g*(h[1]*h[5]-h[2]*h[4]);var o=g*(h[5]*h[6]-h[3]*h[8]);var j=g*(h[0]*h[8]-h[2]*h[6]);var BB=g*(h[2]*h[3]-h[0]*h[5]);var q=g*(h[3]*h[7]-h[4]*h[6]);var AB=g*(h[1]*h[6]-h[0]*h[7]);var k=g*(h[0]*h[4]-h[1]*h[3]);h[0]=DB;h[1]=u;h[2]=l;h[3]=o;h[4]=j;h[5]=BB;h[6]=q;h[7]=AB;h[8]=k;return i;} add( g){h[0]=h[0]+g.h[0];h[1]=h[1]+g.h[1];h[2]=h[2]+g.h[2];h[3]=h[3]+g.h[3];h[4]=h[4]+g.h[4];h[5]=h[5]+g.h[5];h[6]=h[6]+g.h[6];h[7]=h[7]+g.h[7];h[8]=h[8]+g.h[8];return this;} ND( g){h[0]=h[0]-g.h[0];h[1]=h[1]-g.h[1];h[2]=h[2]-g.h[2];h[3]=h[3]-g.h[3];h[4]=h[4]-g.h[4];h[5]=h[5]-g.h[5];h[6]=h[6]-g.h[6];h[7]=h[7]-g.h[7];h[8]=h[8]-g.h[8];return this;} multiply( g){final  u=h[0];final  k=h[3];final  TB=h[6];final  BB=h[1];final  q=h[4];final  ZB=h[7];final  l=h[2];final  PB=h[5];final  DB=h[8];final  j=g.h[0];final  o=g.h[3];final  IB=g.h[6];final  OB=g.h[1];final  NB=g.h[4];final  cB=g.h[7];final  dB=g.h[2];final  AB=g.h[5];final  i=g.h[8];h[0]=(u*j)+(k*OB)+(TB*dB);h[3]=(u*o)+(k*NB)+(TB*AB);h[6]=(u*IB)+(k*cB)+(TB*i);h[1]=(BB*j)+(q*OB)+(ZB*dB);h[4]=(BB*o)+(q*NB)+(ZB*AB);h[7]=(BB*IB)+(q*cB)+(ZB*i);h[2]=(l*j)+(PB*OB)+(DB*dB);h[5]=(l*o)+(PB*NB)+(DB*AB);h[8]=(l*IB)+(PB*cB)+(DB*i);return this;} get right{var i=h[0];var g=h[1];var j=h[2];return new v(i,g,j);}}class CB{final  h=new JC.Float32List(16); index( g, i)=>(i*4)+g; entry( g, i)=>h[index(g,i)];HB( g, i, j){h[index(g,i)]=j;}CB.KI();CB.MI(){sD();} BC( g){h[15]=g.h[15];h[14]=g.h[14];h[13]=g.h[13];h[12]=g.h[12];h[11]=g.h[11];h[10]=g.h[10];h[9]=g.h[9];h[8]=g.h[8];h[7]=g.h[7];h[6]=g.h[6];h[5]=g.h[5];h[4]=g.h[4];h[3]=g.h[3];h[2]=g.h[2];h[1]=g.h[1];h[0]=g.h[0];return this;} toString(){var g='';g='${g}[0] ${TC(0)}\n';g='${g}[1] ${TC(1)}\n';g='${g}[2] ${TC(2)}\n';g='${g}[3] ${TC(3)}\n';return g;} get GE=>4; operator[]( g)=>h[g]; operator[]=( i, g){h[i]=g;} TC( i){var g=new FB.KI();g.h[0]=h[index(i,0)];g.h[1]=h[index(i,1)];g.h[2]=h[index(i,2)];g.h[3]=h[index(i,3)];return g;} pC( g){g.h[0]=h[0];g.h[1]=h[1];g.h[2]=h[2];g.h[3]=h[3];g.h[4]=h[4];g.h[5]=h[5];g.h[6]=h[6];g.h[7]=h[7];g.h[8]=h[8];g.h[9]=h[9];g.h[10]=h[10];g.h[11]=h[11];g.h[12]=h[12];g.h[13]=h[13];g.h[14]=h[14];g.h[15]=h[15];return g;} bK( i){var g=new CB.KI();g.h[15]=h[15]*i;g.h[14]=h[14]*i;g.h[13]=h[13]*i;g.h[12]=h[12]*i;g.h[11]=h[11]*i;g.h[10]=h[10]*i;g.h[9]=h[9]*i;g.h[8]=h[8]*i;g.h[7]=h[7]*i;g.h[6]=h[6]*i;g.h[5]=h[5]*i;g.h[4]=h[4]*i;g.h[3]=h[3]*i;g.h[2]=h[2]*i;g.h[1]=h[1]*i;g.h[0]=h[0]*i;return g;} cK( g){var i=new CB.KI();i.h[0]=(h[0]*g.h[0])+(h[4]*g.h[1])+(h[8]*g.h[2])+(h[12]*g.h[3]);i.h[4]=(h[0]*g.h[4])+(h[4]*g.h[5])+(h[8]*g.h[6])+(h[12]*g.h[7]);i.h[8]=(h[0]*g.h[8])+(h[4]*g.h[9])+(h[8]*g.h[10])+(h[12]*g.h[11]);i.h[12]=(h[0]*g.h[12])+(h[4]*g.h[13])+(h[8]*g.h[14])+(h[12]*g.h[15]);i.h[1]=(h[1]*g.h[0])+(h[5]*g.h[1])+(h[9]*g.h[2])+(h[13]*g.h[3]);i.h[5]=(h[1]*g.h[4])+(h[5]*g.h[5])+(h[9]*g.h[6])+(h[13]*g.h[7]);i.h[9]=(h[1]*g.h[8])+(h[5]*g.h[9])+(h[9]*g.h[10])+(h[13]*g.h[11]);i.h[13]=(h[1]*g.h[12])+(h[5]*g.h[13])+(h[9]*g.h[14])+(h[13]*g.h[15]);i.h[2]=(h[2]*g.h[0])+(h[6]*g.h[1])+(h[10]*g.h[2])+(h[14]*g.h[3]);i.h[6]=(h[2]*g.h[4])+(h[6]*g.h[5])+(h[10]*g.h[6])+(h[14]*g.h[7]);i.h[10]=(h[2]*g.h[8])+(h[6]*g.h[9])+(h[10]*g.h[10])+(h[14]*g.h[11]);i.h[14]=(h[2]*g.h[12])+(h[6]*g.h[13])+(h[10]*g.h[14])+(h[14]*g.h[15]);i.h[3]=(h[3]*g.h[0])+(h[7]*g.h[1])+(h[11]*g.h[2])+(h[15]*g.h[3]);i.h[7]=(h[3]*g.h[4])+(h[7]*g.h[5])+(h[11]*g.h[6])+(h[15]*g.h[7]);i.h[11]=(h[3]*g.h[8])+(h[7]*g.h[9])+(h[11]*g.h[10])+(h[15]*g.h[11]);i.h[15]=(h[3]*g.h[12])+(h[7]*g.h[13])+(h[11]*g.h[14])+(h[15]*g.h[15]);return i;} dK( g){var i=new FB.KI();i.h[3]=(h[3]*g.h[0])+(h[7]*g.h[1])+(h[11]*g.h[2])+(h[15]*g.h[3]);i.h[2]=(h[2]*g.h[0])+(h[6]*g.h[1])+(h[10]*g.h[2])+(h[14]*g.h[3]);i.h[1]=(h[1]*g.h[0])+(h[5]*g.h[1])+(h[9]*g.h[2])+(h[13]*g.h[3]);i.h[0]=(h[0]*g.h[0])+(h[4]*g.h[1])+(h[8]*g.h[2])+(h[12]*g.h[3]);return i;} eK( g){var i=new v.KI();i.h[0]=(h[0]*g.h[0])+(h[4]*g.h[1])+(h[8]*g.h[2])+h[12];i.h[1]=(h[1]*g.h[0])+(h[5]*g.h[1])+(h[9]*g.h[2])+h[13];i.h[2]=(h[2]*g.h[0])+(h[6]*g.h[1])+(h[10]*g.h[2])+h[14];return i;} operator*( g){if(g is double){return bK(g);}if(g is FB){return dK(g);}if(g is v){return eK(g);}if(4==g.GE){return cK(g);}throw new ArgumentError(g);} operator+( i){var g=new CB.KI();g.h[0]=h[0]+i.h[0];g.h[1]=h[1]+i.h[1];g.h[2]=h[2]+i.h[2];g.h[3]=h[3]+i.h[3];g.h[4]=h[4]+i.h[4];g.h[5]=h[5]+i.h[5];g.h[6]=h[6]+i.h[6];g.h[7]=h[7]+i.h[7];g.h[8]=h[8]+i.h[8];g.h[9]=h[9]+i.h[9];g.h[10]=h[10]+i.h[10];g.h[11]=h[11]+i.h[11];g.h[12]=h[12]+i.h[12];g.h[13]=h[13]+i.h[13];g.h[14]=h[14]+i.h[14];g.h[15]=h[15]+i.h[15];return g;} operator-( i){var g=new CB.KI();g.h[0]=h[0]-i.h[0];g.h[1]=h[1]-i.h[1];g.h[2]=h[2]-i.h[2];g.h[3]=h[3]-i.h[3];g.h[4]=h[4]-i.h[4];g.h[5]=h[5]-i.h[5];g.h[6]=h[6]-i.h[6];g.h[7]=h[7]-i.h[7];g.h[8]=h[8]-i.h[8];g.h[9]=h[9]-i.h[9];g.h[10]=h[10]-i.h[10];g.h[11]=h[11]-i.h[11];g.h[12]=h[12]-i.h[12];g.h[13]=h[13]-i.h[13];g.h[14]=h[14]-i.h[14];g.h[15]=h[15]-i.h[15];return g;} KH( j){var i=QD.cos(j);var g=QD.sin(j);var u=h[0]*i+h[8]*g;var AB=h[1]*i+h[9]*g;var k=h[2]*i+h[10]*g;var o=h[3]*i+h[11]*g;var BB=h[0]*-g+h[8]*i;var DB=h[1]*-g+h[9]*i;var l=h[2]*-g+h[10]*i;var q=h[3]*-g+h[11]*i;h[0]=u;h[1]=AB;h[2]=k;h[3]=o;h[8]=BB;h[9]=DB;h[10]=l;h[11]=q;return this;} operator-(){var g=new CB.KI();g[0]=-h[0];g[1]=-h[1];g[2]=-h[2];g[3]=-h[3];return g;} kC(){h[0]=0.0;h[1]=0.0;h[2]=0.0;h[3]=0.0;h[4]=0.0;h[5]=0.0;h[6]=0.0;h[7]=0.0;h[8]=0.0;h[9]=0.0;h[10]=0.0;h[11]=0.0;h[12]=0.0;h[13]=0.0;h[14]=0.0;h[15]=0.0;return this;} sD(){h[0]=1.0;h[1]=0.0;h[2]=0.0;h[3]=0.0;h[4]=0.0;h[5]=1.0;h[6]=0.0;h[7]=0.0;h[8]=0.0;h[9]=0.0;h[10]=1.0;h[11]=0.0;h[12]=0.0;h[13]=0.0;h[14]=0.0;h[15]=1.0;return this;} UE(){var g;g=h[4];h[4]=h[1];h[1]=g;g=h[8];h[8]=h[2];h[2]=g;g=h[12];h[12]=h[3];h[3]=g;g=h[9];h[9]=h[6];h[6]=g;g=h[13];h[13]=h[7];h[7]=g;g=h[14];h[14]=h[11];h[11]=g;return this;} JF(){var k=h[0]*h[5]-h[1]*h[4];var l=h[0]*h[6]-h[2]*h[4];var j=h[0]*h[7]-h[3]*h[4];var g=h[1]*h[6]-h[2]*h[5];var o=h[1]*h[7]-h[3]*h[5];var i=h[2]*h[7]-h[3]*h[6];var u=h[8]*g-h[9]*l+h[10]*k;var AB=h[8]*o-h[9]*j+h[11]*k;var q=h[8]*i-h[10]*j+h[11]*l;var BB=h[9]*i-h[10]*o+h[11]*g;return -BB*h[12]+q*h[13]-AB*h[14]+u*h[15];} PF(){var TB=h[0];var u=h[1];var ZB=h[2];var i=h[3];var k=h[4];var l=h[5];var PB=h[6];var NB=h[7];var DB=h[8];var OB=h[9];var j=h[10];var AB=h[11];var q=h[12];var BB=h[13];var IB=h[14];var o=h[15];var rB=TB*l-u*k;var qB=TB*PB-ZB*k;var sB=TB*NB-i*k;var CC=u*PB-ZB*l;var cB=u*NB-i*l;var DC=ZB*NB-i*PB;var EC=DB*BB-OB*q;var dB=DB*IB-j*q;var FC=DB*o-AB*q;var GC=OB*IB-j*BB;var HC=OB*o-AB*BB;var IC=j*o-AB*IB;var NC=(rB*IC-qB*HC+sB*GC+CC*FC-cB*dB+DC*EC);if(NC==0.0){return NC;}var g=1.0/NC;h[0]=(l*IC-PB*HC+NB*GC)*g;h[1]=(-u*IC+ZB*HC-i*GC)*g;h[2]=(BB*DC-IB*cB+o*CC)*g;h[3]=(-OB*DC+j*cB-AB*CC)*g;h[4]=(-k*IC+PB*FC-NB*dB)*g;h[5]=(TB*IC-ZB*FC+i*dB)*g;h[6]=(-q*DC+IB*sB-o*qB)*g;h[7]=(DB*DC-j*sB+AB*qB)*g;h[8]=(k*HC-l*FC+NB*EC)*g;h[9]=(-TB*HC+u*FC-i*EC)*g;h[10]=(q*cB-BB*sB+o*rB)*g;h[11]=(-DB*cB+OB*sB-AB*rB)*g;h[12]=(-k*GC+l*dB-PB*EC)*g;h[13]=(TB*GC-u*dB+ZB*EC)*g;h[14]=(-q*CC+BB*qB-IB*rB)*g;h[15]=(DB*CC-OB*qB+j*rB)*g;return NC;} add( g){h[0]=h[0]+g.h[0];h[1]=h[1]+g.h[1];h[2]=h[2]+g.h[2];h[3]=h[3]+g.h[3];h[4]=h[4]+g.h[4];h[5]=h[5]+g.h[5];h[6]=h[6]+g.h[6];h[7]=h[7]+g.h[7];h[8]=h[8]+g.h[8];h[9]=h[9]+g.h[9];h[10]=h[10]+g.h[10];h[11]=h[11]+g.h[11];h[12]=h[12]+g.h[12];h[13]=h[13]+g.h[13];h[14]=h[14]+g.h[14];h[15]=h[15]+g.h[15];return this;} ND( g){h[0]=h[0]-g.h[0];h[1]=h[1]-g.h[1];h[2]=h[2]-g.h[2];h[3]=h[3]-g.h[3];h[4]=h[4]-g.h[4];h[5]=h[5]-g.h[5];h[6]=h[6]-g.h[6];h[7]=h[7]-g.h[7];h[8]=h[8]-g.h[8];h[9]=h[9]-g.h[9];h[10]=h[10]-g.h[10];h[11]=h[11]-g.h[11];h[12]=h[12]-g.h[12];h[13]=h[13]-g.h[13];h[14]=h[14]-g.h[14];h[15]=h[15]-g.h[15];return this;} multiply( g){final  u=h[0];final  k=h[4];final  PB=h[8];final  vD=h[12];final  BB=h[1];final  qB=h[5];final  HC=h[9];final  ZB=h[13];final  dB=h[2];final  NB=h[6];final  DC=h[10];final  rB=h[14];final  DB=h[3];final  wD=h[7];final  j=h[11];final  sB=h[15];final  o=g.h[0];final  q=g.h[4];final  IB=g.h[8];final  AB=g.h[12];final  CC=g.h[1];final  GC=g.h[5];final  TB=g.h[9];final  NC=g.h[13];final  cB=g.h[2];final  FC=g.h[6];final  i=g.h[10];final  IC=g.h[14];final  EC=g.h[3];final  OB=g.h[7];final  l=g.h[11];final  xD=g.h[15];h[0]=(u*o)+(k*CC)+(PB*cB)+(vD*EC);h[4]=(u*q)+(k*GC)+(PB*FC)+(vD*OB);h[8]=(u*IB)+(k*TB)+(PB*i)+(vD*l);h[12]=(u*AB)+(k*NC)+(PB*IC)+(vD*xD);h[1]=(BB*o)+(qB*CC)+(HC*cB)+(ZB*EC);h[5]=(BB*q)+(qB*GC)+(HC*FC)+(ZB*OB);h[9]=(BB*IB)+(qB*TB)+(HC*i)+(ZB*l);h[13]=(BB*AB)+(qB*NC)+(HC*IC)+(ZB*xD);h[2]=(dB*o)+(NB*CC)+(DC*cB)+(rB*EC);h[6]=(dB*q)+(NB*GC)+(DC*FC)+(rB*OB);h[10]=(dB*IB)+(NB*TB)+(DC*i)+(rB*l);h[14]=(dB*AB)+(NB*NC)+(DC*IC)+(rB*xD);h[3]=(DB*o)+(wD*CC)+(j*cB)+(sB*EC);h[7]=(DB*q)+(wD*GC)+(j*FC)+(sB*OB);h[11]=(DB*IB)+(wD*TB)+(j*i)+(sB*l);h[15]=(DB*AB)+(wD*NC)+(j*IC)+(sB*xD);return this;} get right{var i=h[0];var g=h[1];var j=h[2];return new v(i,g,j);}} iG( g, o, q, u){var i=o-q;i.normalize();var j=u.FE(i);j.normalize();var k=i.FE(j);k.normalize();g.kC();g.HB(3,3,1.0);g.HB(0,0,j.x);g.HB(1,0,j.y);g.HB(2,0,j.z);g.HB(0,1,k.x);g.HB(1,1,k.y);g.HB(2,1,k.z);g.HB(0,2,i.x);g.HB(1,2,i.y);g.HB(2,2,i.z);g.UE();var l=g*-o;g.HB(0,3,l.x);g.HB(1,3,l.y);g.HB(2,3,l.z);} jG( l, o, q, i, k){var g=QD.tan(o.toDouble()*0.5)*i.toDouble();var j=g*q.toDouble();kG(l,-j,j,-g,g,i,k);} kG( IB, k, o, l, q, j, i){k=k.toDouble();o=o.toDouble();l=l.toDouble();q=q.toDouble();j=j.toDouble();i=i.toDouble();var u=2.0*j;var DB=o-k;var BB=q-l;var AB=i-j;var g=IB.kC();g.HB(0,0,u/DB);g.HB(1,1,u/BB);g.HB(0,2,(o+k)/DB);g.HB(1,2,(q+l)/BB);g.HB(2,2,-(i+j)/AB);g.HB(3,2,-1.0);g.HB(2,3,-(u*i)/AB);} lG( DB, i, o, k, q, l, j){i=i.toDouble();o=o.toDouble();k=k.toDouble();q=q.toDouble();l=l.toDouble();j=j.toDouble();var u=o-i;var IB=o+i;var BB=q-k;var OB=q+k;var AB=j-l;var NB=j+l;var g=DB.kC();g.HB(0,0,2.0/u);g.HB(1,1,2.0/BB);g.HB(2,2,-2.0/AB);g.HB(0,3,-IB/u);g.HB(1,3,-OB/BB);g.HB(2,3,-NB/AB);g.HB(3,3,1.0);}