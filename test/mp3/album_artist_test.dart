// Integration tests for the `albumArtist` field on MP3 files (ID3 TPE2 frame).
//
// These fixtures are large real tracks that live in the repo but are
// gitignored (`test/mp3/黒うさP - 下弦の月.mp3`).
// On CI where the file is absent the tests are skipped instead of failing.
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

const _fixture = 'test/mp3/黒うさP - 下弦の月.mp3';
final _skip = File(_fixture).existsSync() ? false : 'fixture not present';

void main() {
  test('MP3: albumArtist comes from the ID3 TPE2 frame', () {
    final all = readAllMetadata(File(_fixture), getImage: false) as Mp3Metadata;

    expect(all.albumArtist, equals('黒うさP'));
  }, skip: _skip);

  test('MP3: albumArtist is mapped into the generic view', () {
    final metadata = readMetadata(File(_fixture), getImage: false);

    expect(metadata.albumArtist, equals('黒うさP'));
  }, skip: _skip);
}
