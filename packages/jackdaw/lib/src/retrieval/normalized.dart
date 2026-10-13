import 'dart:math' as math;
import 'dart:typed_data';

/// Returns a copy of [vector] scaled to length 1, so a dot product of two
/// normalized vectors is their cosine similarity. A zero vector stays zero.
Float32List normalized(Float32List vector) {
  var sum = 0.0;
  for (final x in vector) {
    sum += x * x;
  }
  final out = Float32List.fromList(vector);
  if (sum == 0) return out;
  final scale = 1 / math.sqrt(sum);
  for (var i = 0; i < out.length; i++) {
    out[i] *= scale;
  }
  return out;
}
