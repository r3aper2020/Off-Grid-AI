import 'dart:typed_data';

import 'package:offgrid_ai/features/maps/data/range_reader.dart';

/// A [RangeReader] over bytes in memory, counting requests.
class MemoryRangeReader implements RangeReader {
  MemoryRangeReader(this.bytes, {this.chunkSize = 4096});
  final Uint8List bytes;
  final int chunkSize;
  int requests = 0;
  int bytesServed = 0;

  @override
  Future<Uint8List> read(int offset, int length) async {
    requests++;
    bytesServed += length;
    return Uint8List.sublistView(bytes, offset, offset + length);
  }

  @override
  Stream<List<int>> stream(int offset, int length) async* {
    requests++;
    bytesServed += length;
    for (var p = offset; p < offset + length; p += chunkSize) {
      final end = p + chunkSize > offset + length
          ? offset + length
          : p + chunkSize;
      yield Uint8List.sublistView(bytes, p, end);
    }
  }

  @override
  void close() {}
}
