import 'dart:js_interop';

import 'package:orchid/chat/model.dart';

@JS()
@staticInterop
@anonymous
class ModelInfoJS {
  // Factory constructor to initialize ModelInfoJS
  external factory ModelInfoJS({
    required String id,
    required String name,
    required String provider,
    required String apiType,
  });

  // Static method to create a ModelInfoJS from a Dart ModelInfo object
  static ModelInfoJS fromModelInfo(ModelInfo modelInfo) {
    return ModelInfoJS(
      id: modelInfo.id,
      name: modelInfo.name,
      provider: modelInfo.provider,
      apiType: modelInfo.apiType,
    );
  }

  // Static method to map a list of ModelInfo to a list of ModelInfoJS
  static List<ModelInfoJS> fromModelInfos(List<ModelInfo> modelInfos) {
    return modelInfos.map((info) => fromModelInfo(info)).toList();
  }
}

extension ModelInfoJSExtension on ModelInfoJS {
  external String id;
  external String name;
  external String provider;
  external String apiType;
}
