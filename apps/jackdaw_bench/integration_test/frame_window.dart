import 'dart:ui' show FramePhase, FrameTiming;

/// The frames of [frames] whose build started in [from, to), in
/// microseconds of the timeline clock.
List<FrameTiming> framesWithin(List<FrameTiming> frames, int from, int to) => [
  for (final f in frames)
    if (f.timestampInMicroseconds(FramePhase.buildStart) case final at
        when at >= from && at < to)
      f,
];
