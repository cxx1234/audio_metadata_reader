// Integration tests for the `albumArtist` field on FLAC files (Vorbis comments).
//
// These fixtures are large real tracks that live in the repo but are
// gitignored (`test/flac/幽閉サテライト - 大地に咲く旋律 (with senya).flac`).
// On CI where the file is absent the tests are skipped instead of failing.
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

const _fixture = 'test/flac/幽閉サテライト - 大地に咲く旋律 (with senya).flac';
final _skip = File(_fixture).existsSync() ? false : 'fixture not present';

void main() {
  test('FLAC: albumArtist comes from the Vorbis ALBUMARTIST comment', () {
    final all =
        readAllMetadata(File(_fixture), getImage: false) as VorbisMetadata;

    expect(all.albumArtist, equals(['幽閉サテライト']));
  }, skip: _skip);

  test('FLAC: albumArtist is mapped into the generic view', () {
    final metadata = readMetadata(File(_fixture), getImage: false);

    expect(metadata.albumArtist, equals('幽閉サテライト'));
  }, skip: _skip);

  test('FLAC: ALBUMARTIST no longer leaks into the artist list', () {
    final all =
        readAllMetadata(File(_fixture), getImage: false) as VorbisMetadata;

    expect(all.artist, isNotEmpty);
    expect(all.artist, isNot(contains('幽閉サテライト')));
  }, skip: _skip);
}
