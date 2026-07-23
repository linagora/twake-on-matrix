import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/base/perf_collector.dart';

FrameTiming frameTiming({
  required int vsyncStartUs,
  int buildUs = 5000,
  int rasterUs = 6000,
}) {
  final buildStartUs = vsyncStartUs + 100;
  final buildFinishUs = buildStartUs + buildUs;
  final rasterStartUs = buildFinishUs + 100;
  final rasterFinishUs = rasterStartUs + rasterUs;
  return FrameTiming(
    vsyncStart: vsyncStartUs,
    buildStart: buildStartUs,
    buildFinish: buildFinishUs,
    rasterStart: rasterStartUs,
    rasterFinish: rasterFinishUs,
    rasterFinishWallTime: rasterFinishUs,
  );
}

void main() {
  test('computes effective FPS from the observed vsync window', () {
    final frames = List.generate(
      31,
      (index) => frameTiming(vsyncStartUs: index * 16667),
    );

    final metrics = computeFrameStats(frames);

    expect(metrics['frame_count'], 31);
    expect(metrics['frame_window_ms'], closeTo(500.01, 0.01));
    expect(double.parse(metrics['fps'] as String), closeTo(60, 0.1));
    expect(metrics['jank_count'], 0);
    expect(metrics['jank_rate'], '0.000');
  });

  test('does not add build and raster durations when classifying jank', () {
    final metrics = computeFrameStats([
      frameTiming(vsyncStartUs: 0, buildUs: 10000, rasterUs: 10000),
      frameTiming(vsyncStartUs: 16667, buildUs: 17000, rasterUs: 1000),
      frameTiming(vsyncStartUs: 33334, buildUs: 1000, rasterUs: 18000),
    ]);

    expect(metrics['jank_count'], 2);
    expect(metrics['jank_rate'], '0.667');
  });

  test('keeps a zero FPS marker when the sample has no time window', () {
    final metrics = computeFrameStats([frameTiming(vsyncStartUs: 1000)]);

    expect(metrics['frame_count'], 1);
    expect(metrics['frame_window_ms'], 0);
    expect(metrics['fps'], '0.00');
  });
}
