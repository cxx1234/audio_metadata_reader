#!/usr/bin/env python3
"""Inject a standard ID3v2.4 USLT frame into an MP3 produced by ffmpeg.

ffmpeg writes the `lyrics` metadata tag of an MP3 as a non-standard
`TXXX` frame whose description is `USLT`. audio_metadata_reader only reads
the standard `USLT` frame, so this helper rewrites the file:

  1. parse the existing ID3v2.4 frames
  2. drop the non-standard `TXXX:USLT` frame
  3. append a standard `USLT` frame (UTF-8, lang=eng, empty descriptor)
  4. update the tag size (synchsafe) and rewrite the file

Usage:
  python3 tool/make_mp3_uslt.py <input.mp3> <lyrics.txt>
"""

from __future__ import annotations

import sys

USLT_DESCRIPTOR_LANG = b"eng"


def synchsafe(value: int) -> bytes:
    """Encode an integer as a 4-byte ID3v2.4 synchsafe integer."""
    return bytes(
        [
            (value >> 21) & 0x7F,
            (value >> 14) & 0x7F,
            (value >> 7) & 0x7F,
            value & 0x7F,
        ]
    )


def read_synchsafe(raw: bytes) -> int:
    """Decode a 4-byte ID3v2.4 synchsafe integer."""
    return (
        ((raw[0] & 0x7F) << 21)
        | ((raw[1] & 0x7F) << 14)
        | ((raw[2] & 0x7F) << 7)
        | (raw[3] & 0x7F)
    )


def parse_frames(tag: bytes) -> list[bytes]:
    """Split an ID3v2.4 tag body into its raw frames."""
    frames: list[bytes] = []
    position = 0
    while position < len(tag):
        frame_id = tag[position : position + 4]
        if frame_id == b"\x00\x00\x00\x00":
            break  # padding
        size = read_synchsafe(tag[position + 4 : position + 8])
        frames.append(tag[position : position + 10 + size])
        position += 10 + size
    return frames


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    input_path, lyrics_path = sys.argv[1], sys.argv[2]
    with open(lyrics_path, "r", encoding="utf-8") as handle:
        lyrics = handle.read()

    data = bytearray(open(input_path, "rb").read())
    if bytes(data[:3]) != b"ID3" or data[3] != 4:
        print(f"error: {input_path} is not an ID3v2.4 MP3")
        sys.exit(1)

    tag_size = read_synchsafe(bytes(data[6:10]))
    tag = bytes(data[10 : 10 + tag_size])

    # Keep every frame except the non-standard TXXX:USLT one. The frame body
    # starts at offset 10, so search the whole frame for the "USLT" descriptor.
    kept_frames = [
        frame
        for frame in parse_frames(tag)
        if not (frame[:4] == b"TXXX" and b"USLT" in frame[10:])
    ]

    # Standard USLT frame: encoding(3=UTF-8) + lang(3) + descriptor(00) + text.
    uslt_content = b"\x03" + USLT_DESCRIPTOR_LANG + b"\x00" + lyrics.encode("utf-8")
    uslt_frame = b"USLT" + synchsafe(len(uslt_content)) + b"\x00\x00" + uslt_content
    kept_frames.append(uslt_frame)

    new_tag = b"".join(kept_frames)
    new_size = len(new_tag)

    # Reassemble: ID3v2.4 header + tag + original audio stream.
    new_file = bytearray(data[:10])
    new_file[6:10] = synchsafe(new_size)
    new_file += new_tag
    new_file += data[10 + tag_size :]

    with open(input_path, "wb") as handle:
        handle.write(bytes(new_file))

    print(f"injected standard USLT frame into {input_path} (tag={new_size} bytes)")


if __name__ == "__main__":
    main()
