import 'dart:typed_data';

import 'package:jsontool/jsontool.dart';

/// Returns a deep copy of the [topology] with the most precise types for the
/// structure by traversing and rebuilding on the way back.
Map<String?, dynamic> parseObject(Object topology) =>
    _jsonTopology(JsonReader.fromObject(topology));

/// Equivalent to [parseObject] except it accepts the [topology] as string.
Map<String?, dynamic> parseString(String topology) =>
    _jsonTopology(JsonReader.fromString(topology));

/// Equivalent to [parseObject] except it accepts the [topology] as utf8.
Map<String?, dynamic> parseUtf8(Uint8List topology) =>
    _jsonTopology(JsonReader.fromUtf8(topology));

JsonBuilder _jsonTopology = jsonStruct({
  "type": jsonString,
  "bbox": _jsonBbox,
  "transform": _jsonTransform,
  "objects": _jsonObjects,
  "arcs": _jsonArcs
}, jsonValue);

JsonBuilder _jsonBbox = jsonArray(jsonNum);

JsonBuilder _jsonTransform = jsonObject(jsonArray(jsonNum));

JsonBuilder _jsonObjects = jsonObject(_jsonGeometryObject);

JsonBuilder<Map<String?, dynamic>> _jsonGeometryObject = (reader) {
  reader.expectObject();
  var result = <String?, dynamic>{};
  String? key, type, geometry;
  JsonReader? pending;
  while (reader.hasNextKey()) {
    if ((key = reader.tryKey(["type"])) != null) {
      result[key] = (type = reader.expectString());
      if (pending != null) result[geometry] = _jsonGeometry[type]!(pending);
    } else if ((key = reader.tryKey(["arcs", "coordinates", "geometries"])) !=
        null) {
      geometry = key;
      if (type != null) {
        result[geometry] = _jsonGeometry[type]!(reader);
      } else {
        pending = reader.copy();
        reader.skipAnyValue();
      }
    } else {
      result[reader.nextKey()] = jsonValue(reader);
    }
  }
  return result;
};

Map<String?, JsonBuilder> _jsonGeometry = {
  "Point": jsonArray(jsonValue),
  "MultiPoint": jsonArray(jsonArray(jsonValue)),
  "LineString": jsonArray(jsonInt),
  "MultiLineString": jsonArray(jsonArray(jsonInt)),
  "Polygon": jsonArray(jsonArray(jsonInt)),
  "MultiPolygon": jsonArray(jsonArray(jsonArray(jsonInt))),
  "GeometryCollection": jsonArray(_jsonGeometryObject)
};

JsonBuilder _jsonArcs = jsonArray(jsonArray(jsonArray(jsonValue)));
