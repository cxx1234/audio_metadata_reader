// Integration tests for the `albumArtist` field on MP3 files (ID3 TPE2 frame)
// and the `artist`/`albumArtist` split in the generic view.
//
// The `tpe1_tpe2.mp3` fixture is pre-generated with ffmpeg (see AGENTS.md)
// and carries distinct TPE1 (lead performer) and TPE2 (album artist) values.
//
// `黒うさP - 下弦の月.mp3` is a large real track that is gitignored; on CI
// where the file is absent those tests are skipped instead of failing.
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

const _tpeFixture = 'test/mp3/tpe1_tpe2.mp3';
const _realFixture = 'test/mp3/黒うさP - 下弦の月.mp3';
final _skipReal =
    File(_realFixture).existsSync() ? false : 'fixture not present';

void main() {
  group('MP3 TPE1/TPE2 split (ffmpeg fixture)', () {
    test('generic view: artist is TPE1, albumArtist is TPE2', () {
      final metadata = readMetadata(File(_tpeFixture), getImage: false);

      // TPE1 (lead performer) must win over TPE2 (album artist) for `artist`.
      expect(metadata.artist, equals('Solo Artist'));
      expect(metadata.albumArtist, equals('Band Name'));
    });

    test('format view: leadPerformer is TPE1, bandOrOrchestra is TPE2', () {
      final all =
          readAllMetadata(File(_tpeFixture), getImage: false) as Mp3Metadata;

      expect(all.leadPerformer, equals('Solo Artist'));
      expect(all.bandOrOrchestra, equals('Band Name'));
      expect(all.albumArtist, equals('Band Name'));
    });
  });

  group('MP3 albumArtist from real track', () {
    test('MP3: albumArtist comes from the ID3 TPE2 frame', () {
      final all =
          readAllMetadata(File(_realFixture), getImage: false) as Mp3Metadata;

      expect(all.albumArtist, equals('黒うさP'));
    }, skip: _skipReal);

    test('MP3: albumArtist is mapped into the generic view', () {
      final metadata = readMetadata(File(_realFixture), getImage: false);

      expect(metadata.albumArtist, equals('黒うさP'));
    }, skip: _skipReal);

    test('MP3: generic artist is the TPE1 lead performer, not TPE2', () {
      final metadata = readMetadata(File(_realFixture), getImage: false);

      // TPE1 is 黒うさP/96猫 (lead performer); TPE2 is 黒うさP (album artist).
      expect(metadata.artist, equals('黒うさP/96猫'));
    }, skip: _skipReal);
  });
}
