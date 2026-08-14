import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

void main() {
  test('albumArtist round-trips through Mp4Writer', () {
    final dir = Directory.systemTemp.createTempSync();
    addTearDown(() => dir.deleteSync(recursive: true));
    final target = File('${dir.path}/track.m4a');
    target.writeAsBytesSync(File('test/mp4/track.m4a').readAsBytesSync());

    final metadata = readAllMetadata(target, getImage: false) as Mp4Metadata;
    metadata.albumArtist = 'Test Album Artist';

    Mp4Writer().write(target, metadata);

    final reRead = readAllMetadata(target, getImage: false) as Mp4Metadata;
    expect(reRead.albumArtist, equals('Test Album Artist'));
  });
}
