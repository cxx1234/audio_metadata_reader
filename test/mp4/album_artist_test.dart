// Integration tests for the `albumArtist` field on M4A/MP4 files (aART atom).
//
// These fixtures are large real tracks that live in the repo but are
// gitignored (`test/mp4/SawanoHiroyuki[nZk] - Unti-L.m4a`).
// On CI where the file is absent the tests are skipped instead of failing.
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

const _fixture = 'test/mp4/SawanoHiroyuki[nZk] - Unti-L.m4a';
final _skip = File(_fixture).existsSync() ? false : 'fixture not present';

void main() {
  test('M4A: albumArtist comes from the aART atom', () {
    final all = readAllMetadata(File(_fixture), getImage: false) as Mp4Metadata;

    expect(all.albumArtist, equals('SawanoHiroyuki[nZk]'));
  }, skip: _skip);

  test('M4A: albumArtist is mapped into the generic view', () {
    final metadata = readMetadata(File(_fixture), getImage: false);

    expect(metadata.albumArtist, equals('SawanoHiroyuki[nZk]'));
  }, skip: _skip);
}
