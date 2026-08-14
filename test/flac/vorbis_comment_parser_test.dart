import 'dart:convert';

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parsers/tags/vorbis_comment.dart';
import 'package:test/test.dart';

void main() {
  test('Parse LANGUAGE Vorbis comment into dedicated field', () {
    final metadata = VorbisMetadata();

    parseVorbisComment('LANGUAGE=ja'.codeUnits, metadata, fetchImage: false);

    expect(metadata.language, equals(['ja']));
    expect(metadata.unknowns.containsKey('LANGUAGE'), isFalse);
  });

  test('Parse LANG Vorbis comment alias into dedicated field', () {
    final metadata = VorbisMetadata();

    parseVorbisComment('LANG=zh-CN'.codeUnits, metadata, fetchImage: false);

    expect(metadata.language, equals(['zh-CN']));
    expect(metadata.unknowns.containsKey('LANG'), isFalse);
  });

  test('LENGTH does not overwrite duration from STREAMINFO', () {
    final metadata = VorbisMetadata()..duration = const Duration(seconds: 236);

    parseVorbisComment('LENGTH=236'.codeUnits, metadata, fetchImage: false);

    expect(metadata.duration, const Duration(seconds: 236));
  });

  test('Parse ALBUMARTIST Vorbis comment into dedicated field', () {
    final metadata = VorbisMetadata();

    parseVorbisComment(utf8.encode('ALBUMARTIST=幽閉サテライト'), metadata,
        fetchImage: false);

    expect(metadata.albumArtist, equals(['幽閉サテライト']));
    expect(metadata.artist, isEmpty);
    expect(metadata.unknowns.containsKey('ALBUMARTIST'), isFalse);
  });

  test('ARTIST and ALBUMARTIST stay separated', () {
    final metadata = VorbisMetadata();

    parseVorbisComment(utf8.encode('ARTIST=森永真由美'), metadata,
        fetchImage: false);
    parseVorbisComment(utf8.encode('ALBUMARTIST=幽閉サテライト'), metadata,
        fetchImage: false);

    expect(metadata.artist, equals(['森永真由美']));
    expect(metadata.albumArtist, equals(['幽閉サテライト']));
  });
}
