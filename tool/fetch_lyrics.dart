import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:audio_metadata_reader/src/metadata/base.dart';

// Note: `ParserTag` (the sealed base class returned by `readAllMetadata`) is
// not re-exported by the public entrypoint, hence the deep import above.
// `RiffMetadata` and `ApeMetadata` are available from the public entrypoint.

/// Demo tool: extract the embedded lyrics of audio files and print them.
///
/// Usage:
///   dart run tool/fetch_lyrics.dart                  # scan test/lyrics fixtures
///   dart run tool/fetch_lyrics.dart <path> [path...] # scan the given files
///
/// For every file it prints:
///   - the container format and the tag that carries the lyrics
///   - the lyrics text (exactly as stored in the file)
void main(List<String> arguments) {
  final List<File> targets = _resolveTargets(arguments);

  for (final File file in targets) {
    _printLyrics(file);
  }
}

/// Resolve the files to scan: explicit paths from the CLI, or the generated
/// fixtures under `test/lyrics/` when no argument is given.
List<File> _resolveTargets(List<String> arguments) {
  if (arguments.isNotEmpty) {
    return <File>[for (final String path in arguments) File(path)];
  }

  const List<String> fixtures = <String>[
    'test/lyrics/lyrics.mp3',
    'test/lyrics/lyrics.flac',
    'test/lyrics/lyrics.m4a',
    'test/lyrics/lyrics.ogg',
    'test/lyrics/lyrics.opus',
  ];

  return <File>[for (final String path in fixtures) File(path)];
}

/// Print the embedded lyrics of a single file.
void _printLyrics(File file) {
  final String path = file.path;

  print('──────────────────────────────────────────');
  print('File: $path');

  if (!file.existsSync()) {
    print('  (not found, skipped)');
    return;
  }

  try {
    // Format-specific view: it tells us which tag actually carried the lyrics.
    final ParserTag all = readAllMetadata(file, getImage: false);

    // Sealed switch: the five ParserTag subtypes are exhaustive.
    final String? formatLyrics = switch (all) {
      Mp3Metadata m => _labelAndValue('ID3v2 USLT', m.lyric),
      Mp4Metadata m => _labelAndValue('MP4 ©lyr', m.lyrics),
      VorbisMetadata m => _labelAndValue('Vorbis LYRICS', m.lyric),
      ApeMetadata m => _labelAndValue('APE LYRICS', m.lyric),
      RiffMetadata() => null, // RIFF containers have no lyrics tag.
    };

    // Generic view: the field your app would read day to day.
    final AudioMetadata common = readMetadata(file, getImage: false);

    print('  Format-specific lyrics:');
    print(formatLyrics == null ? '    (no lyrics)' : formatLyrics);
    print('  Generic AudioMetadata.lyrics:');
    print(common.lyrics == null ? '    (no lyrics)' : '    ${common.lyrics}');
  } catch (error) {
    print('  Error while parsing: $error');
  }
}

/// Return a human-readable label + value pair, or `null` when there is no
/// lyrics text.
String? _labelAndValue(String label, String? value) {
  if (value == null) {
    return null;
  }
  return '    [$label] $value';
}
