import 'dart:typed_data';

/// Allocates about 48 MB that dies at once, keeping at most 1 MB alive,
/// so the young generation fills and collects at least twice and objects
/// built just before are promoted. A pair of screens mounted together is
/// otherwise first copied in a collection during the writes, a pause of
/// up to 40 ms that belongs to building the screens, not to writing.
int settleHeap() {
  final ring = List<Uint8List?>.filled(16, null);
  var touched = 0;
  for (var i = 0; i < 768; i++) {
    final chunk = Uint8List(64 * 1024)..[0] = i & 0xff;
    ring[i % ring.length] = chunk;
    touched += chunk[0];
  }
  return touched;
}
