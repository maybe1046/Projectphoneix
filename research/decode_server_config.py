"""Decode the server config table out of a captured CoA login.

At login the world server pushes a table of tunable rule values - draft rewards,
unlock levels, feature flags. None of it exists on disk; it is server-authored
and dies with the server.

Wire layout, established from the capture:

    uint32  keyLength
    char[]  key             ("CONFIG_...", ASCII, no NUL)
    value                   1 byte OR 4 bytes, little-endian

There is no type tag. The value width is not declared anywhere, so it has to be
inferred: try 1 byte, try 4 bytes, and keep whichever leaves the stream sitting
on a valid next record (a length prefix that matches a real "CONFIG_" key, or
clean end of block). Feature flags turned out to be 1 byte, numeric settings
4 bytes, which is why a fixed-width read produces plausible-looking rubbish
for the flags - CONFIG_BUILD_DRAFT_ENABLED reads as 5889 instead of 1.

WoW 3.3.5 encrypts only the packet header, never the body, so this decodes
straight out of a passive capture with no session key.

Usage:  python decode_server_config.py <tcp-payload-hex-file> [out.csv]
"""

import csv
import io
import re
import struct
import sys

KEY_RE = re.compile(rb"^CONFIG_[A-Z0-9_]+$")
MAX_KEY = 120


def load_payload(path):
    data = bytearray()
    for line in io.open(path, encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            data += bytes.fromhex(line)
        except ValueError:
            pass          # tshark emits an occasional malformed row
    return bytes(data)


def _key_at(data, pos):
    """If a well-formed [len][CONFIG_key] record starts at pos, return (key, end)."""
    if pos < 0 or pos + 4 > len(data):
        return None
    n = struct.unpack_from("<I", data, pos)[0]
    if not (8 <= n <= MAX_KEY) or pos + 4 + n > len(data):
        return None
    key = data[pos + 4: pos + 4 + n]
    if not KEY_RE.match(key):
        return None
    return key.decode("ascii"), pos + 4 + n


def decode(data):
    """Walk each run of config records, inferring value width per record."""
    rows, seen = [], set()

    # Every run starts at the first key whose length prefix validates.
    starts = []
    for m in re.finditer(rb"CONFIG_[A-Z0-9_]+", data):
        if _key_at(data, m.start() - 4):
            starts.append(m.start() - 4)

    for start in starts:
        pos = start
        while True:
            got = _key_at(data, pos)
            if not got:
                break
            key, after = got

            # Choose the value width that leaves us on a valid next record.
            width = None
            for w in (1, 4):
                if after + w > len(data):
                    continue
                if _key_at(data, after + w) or after + w == len(data):
                    width = w
                    break
            if width is None:
                # Last record of a run, or followed by something else entirely.
                # A 1-byte flag is the safer default only when the next 4 bytes
                # cannot be a value at all; otherwise stop rather than guess.
                break

            value = (data[after] if width == 1
                     else struct.unpack_from("<I", data, after)[0])
            if key not in seen:
                seen.add(key)
                rows.append((key, value, width))
            pos = after + width

    return sorted(rows)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    data = load_payload(sys.argv[1])
    rows = decode(data)

    print("payload bytes : %d" % len(data))
    print("config entries: %d" % len(rows))
    w1 = sum(1 for r in rows if r[2] == 1)
    print("  1-byte flags: %d" % w1)
    print("  4-byte ints : %d" % (len(rows) - w1))

    if len(sys.argv) > 2:
        with io.open(sys.argv[2], "w", encoding="utf-8", newline="") as fh:
            wr = csv.writer(fh)
            wr.writerow(["key", "value", "width_bytes"])
            wr.writerows(rows)
        print("wrote", sys.argv[2])
    return 0


if __name__ == "__main__":
    sys.exit(main())
