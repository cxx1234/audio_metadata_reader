import 'dart:io';

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parser.dart';
import 'package:audio_metadata_reader/src/parsers/tags/tag_parser.dart';
import 'package:test/test.dart';

/// Multi-line LRC lyrics embedded in the fixtures under `test/lyrics/`.
///
/// All fixtures are generated with ffmpeg (see AGENTS.md) so the same lyrics
/// text is stored in every container:
/// - MP3  : ID3v2 USLT frame (unsynchronised lyrics)
/// - FLAC : Vorbis comment `LYRICS`
/// - M4A  : MP4 `©lyr` atom
/// - OGG  : Vorbis comment `LYRICS`
/// - Opus : Vorbis comment `LYRICS`
const String kDemoLyrics = """[00:00.00]Test lyrics demo
[00:05.00]First line of the song
[00:10.00]Second line of the song
[00:15.00]Third and final line""";

/// One fixture entry: relative path, the expected metadata model and the
/// underlying tag that carries the lyrics.
const List<({String path, String format, String tag})> kFixtures =
    <({String path, String format, String tag})>[
  (path: 'test/lyrics/lyrics.mp3', format: 'MP3', tag: 'ID3v2 USLT'),
  (path: 'test/lyrics/lyrics.flac', format: 'FLAC', tag: 'Vorbis LYRICS'),
  (path: 'test/lyrics/lyrics.m4a', format: 'M4A', tag: 'MP4 ©lyr'),
  (path: 'test/lyrics/lyrics.ogg', format: 'OGG', tag: 'Vorbis LYRICS'),
  (path: 'test/lyrics/lyrics.opus', format: 'Opus', tag: 'Vorbis LYRICS'),
];

/// Extract the lyrics field from the format-specific metadata object.
String? lyricsFromAllMetadata(ParserTag all) {
  return switch (all) {
    Mp3Metadata m => m.lyric,
    Mp4Metadata m => m.lyrics,
    VorbisMetadata m => m.lyric,
    ApeMetadata m => m.lyric,
    _ => null,
  };
}

void main() {
  group('Embedded lyrics extraction', () {
    for (final ({String path, String format, String tag}) entry in kFixtures) {
      final String label = '${entry.format} (${entry.tag})';

      test('readMetadata exposes lyrics from $label', () {
        final File track = File(entry.path);
        final AudioMetadata metadata = readMetadata(track, getImage: false);

        expect(metadata.lyrics, kDemoLyrics,
            reason: '${entry.format} should expose the embedded lyrics');
      });

      test('readAllMetadata exposes lyrics from $label', () {
        final File track = File(entry.path);
        final ParserTag all = readAllMetadata(track, getImage: false);

        expect(lyricsFromAllMetadata(all), kDemoLyrics);
      });

      test('lyrics from $label keep their line breaks', () {
        final File track = File(entry.path);
        final AudioMetadata metadata = readMetadata(track, getImage: false);

        expect(metadata.lyrics!.split('\n').length, greaterThan(1),
            reason: 'multi-line lyrics must keep their line breaks');
      });
    }
  });

  group('Lyrics-free formats', () {
    test('WAV has no embedded lyrics (RIFF has no lyrics tag)', () {
      final File track = File('./test/wav/minimal.wav');
      if (!track.existsSync()) {
        return; // Skip silently when the fixture is absent.
      }
      final AudioMetadata metadata = readMetadata(track, getImage: false);

      expect(metadata.lyrics, isNull);
    });

    test('AIFF has no embedded lyrics', () {
      final File track = File('./test/aiff/minimal.aiff');
      if (!track.existsSync()) {
        return; // Skip silently when the fixture is absent.
      }
      final AudioMetadata metadata = readMetadata(track, getImage: false);

      expect(metadata.lyrics, isNull);
    });
  });
}
