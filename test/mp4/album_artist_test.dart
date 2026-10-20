// Tests for the `albumArtist` field on M4A/MP4 files (aART atom).
//
// The first two tests use a large real track that lives in the repo but is
// gitignored (`test/mp4/SawanoHiroyuki[nZk] - Unti-L.m4a`). On CI where the
// file is absent they are skipped instead of failing.
//
// The remaining tests build tiny MP4 files in memory, so they always run.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

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

  test('M4A: aART is kept apart from the ©ART track artist', () {
    final File file = _buildMp4(<Uint8List>[
      _textAtom('\u00A9ART', 'Track Artist'),
      _textAtom('aART', 'Album Artist'),
    ]);
    addTearDown(() => file.deleteSync());

    final metadata = readMetadata(file, getImage: false);

    expect(metadata.artist, equals('Track Artist'));
    expect(metadata.albumArtist, equals('Album Artist'));
  });

  test('M4A: an empty aART atom is skipped instead of failing', () {
    // A size-8 atom has no payload at all, so it cannot contain the nested
    // `data` box. It used to make the parser throw while slicing the payload.
    final File file = _buildMp4(<Uint8List>[
      _makeBox('aART', <int>[]),
      _textAtom('\u00A9nam', 'Title'),
    ]);
    addTearDown(() => file.deleteSync());

    final metadata = readMetadata(file, getImage: false);

    expect(metadata.title, equals('Title'));
    expect(metadata.albumArtist, isNull);
  });
}

/// Build a minimal MP4 file whose `ilst` holds [tagAtoms].
///
/// Layout used by the parser: `ftyp`, then `moov` -> `udta` -> `meta` -> `ilst`.
/// `meta` keeps its 4-byte version/flags prefix, which is the usual layout.
File _buildMp4(List<Uint8List> tagAtoms) {
  final List<int> ilstPayload = <int>[
    for (final Uint8List atom in tagAtoms) ...atom,
  ];

  final Uint8List ftyp = _makeBox('ftyp', <int>[
    ...ascii.encode('M4A '),
    ..._u32(0),
    ...ascii.encode('isom'),
    ...ascii.encode('M4A '),
  ]);
  final Uint8List meta = _makeBox('meta', <int>[
    ..._u32(0), // version + flags
    ..._makeBox('ilst', ilstPayload),
  ]);
  final Uint8List moov = _makeBox('moov', _makeBox('udta', meta));

  return createTemporaryFile(
    'mp4_album_artist_${DateTime.now().microsecondsSinceEpoch}.m4a',
    Uint8List.fromList(<int>[...ftyp, ...moov]),
  );
}

/// Build a text atom such as `©ART` or `aART`, carrying one inner `data` box.
Uint8List _textAtom(String type, String value) {
  final Uint8List data = _makeBox('data', <int>[
    ..._u32(1), // version 0 + well-known type 1: UTF-8 text
    ..._u32(0), // locale
    ...utf8.encode(value),
  ]);

  return _makeBox(type, data);
}

Uint8List _makeBox(String type, List<int> payload) {
  final BytesBuilder builder = BytesBuilder()
    // latin1 keeps the single-byte `©` (0xA9) intact, as ASCII alone cannot.
    ..add(_u32(payload.length + 8))
    ..add(latin1.encode(type))
    ..add(payload);

  return builder.toBytes();
}

Uint8List _u32(int value) {
  final ByteData data = ByteData(4)..setUint32(0, value);

  return data.buffer.asUint8List();
}
