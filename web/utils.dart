import 'dart:async';
import 'dart:html';
import 'package:glf/glf_asset_pack.dart';
import 'package:asset_pack/asset_pack.dart';

AssetManager initAssetManager(gl) {
  var tracer = new AssetPackTrace();
  var stream = tracer.asStream().asBroadcastStream();
  new ProgressControler(querySelector("#assetload")).bind(stream);
  new EventsPrintControler().bind(stream);

  var b = new AssetManager(tracer);
  b.loaders['img'] = new ImageLoader();
  b.importers['img'] = new NoopImporter();
  registerGlfWithAssetManager(gl, b);
  return b;
}

class EventsPrintControler {

  EventsPrintControler();

  StreamSubscription bind(Stream<AssetPackTraceEvent> tracer) {
    return tracer.listen(onEvent);
  }

  void onEvent(AssetPackTraceEvent event) {
    print("AssetPackTraceEvent : ${event}");
  }
}

class Tick {
  double _t = -1.0;
  double _tr = 0.0;
  double _dt  = 0.0;
  bool _started = false;
  get dt => _dt;
  get time => _t;
  get tr => _tr;

  update(ntr) {
    if (_started) {
      _dt = (ntr - _tr);
      _t = _t + _dt;
    } else {
      _started = true;
    }
    _tr = ntr;
  }

  reset() {
    _started = false;
    _t = 0.0;
    _tr = 0.0;
    _dt  = 0.0;
  }
}
