"""Harvest everything readable out of the CoA capture files.

WoW 3.3.5 encrypts only the per-message header, so message *bodies* are plaintext
and can be mined with no session key. This pulls out the four things that have
proven recoverable, and reports which custom systems the capture has evidence
for - so a play session can be steered at whatever is still missing.

Run it repeatedly while capturing; it is cumulative over all pcapng files.

Usage:  python harvest_capture.py [capture_dir] [out_dir]
"""

import collections
import glob
import io
import json
import os
import re
import subprocess
import sys

TSHARK = r"C:\Program Files\Wireshark\tshark.exe"
GAME_IPS = ("51.254.7.227", "51.210.230.10")

# Custom systems, keyed to strings that only appear when that system talks.
SYSTEM_MARKERS = {
    "skill cards":      (rb"SKILL_?CARD", rb"SealedCard", rb"BoosterPack"),
    "draft / build":    (rb"BUILD_DRAFT", rb"DRAFT_", rb"BuildDraft"),
    "mystic enchant":   (rb"MYSTIC", rb"RANDOM_ENCHANT", rb"Reforge"),
    "transmog":         (rb"TRANSMOG", rb"Appearance", rb"Outfit"),
    "wildcard":         (rb"WILDCARD", rb"Wildcard"),
    "advancement":      (rb"CHARACTER_ADVANCEMENT", rb"Advancement", rb"Ascension Point"),
    "challenge/mythic": (rb"CHALLENGE", rb"MYTHIC", rb"Keystone"),
    "manastorm":        (rb"MANASTORM", rb"Manastorm"),
    "collections":      (rb"VANITY", rb"Collection"),
    "hand of fate":     (rb"HAND_OF_FATE", rb"HandOfFate"),
    "auction house":    (rb"Auction", rb"AUCTION"),
    "mail":             (rb"COD ", rb"Mailbox", rb"MAIL_"),
    "professions":      (rb"TradeSkill", rb"Recipe", rb"SKILL_LINE"),
}


def payloads(capture_dir):
    """Concatenated server->client TCP payload across every capture file."""
    data = bytearray()
    files = sorted(glob.glob(os.path.join(capture_dir, "*.pcapng")))
    for f in files:
        for ip in GAME_IPS:
            try:
                out = subprocess.run(
                    [TSHARK, "-r", f, "-Y",
                     "ip.src==%s && tcp.len>0" % ip,
                     "-T", "fields", "-e", "tcp.payload"],
                    capture_output=True, timeout=600).stdout
            except Exception:
                continue
            for line in out.split():
                try:
                    data += bytes.fromhex(line.decode())
                except ValueError:
                    pass
    return bytes(data), files


def main():
    cap = sys.argv[1] if len(sys.argv) > 1 else r"D:\coa-capture"
    out = sys.argv[2] if len(sys.argv) > 2 else r"D:\Projects\projectphoneix\research"

    data, files = payloads(cap)
    print("capture files : %d" % len(files))
    print("payload bytes : %d" % len(data))
    if not data:
        return 1

    # --- config table -----------------------------------------------------
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from decode_server_config import decode as decode_cfg
    cfg = decode_cfg(data)
    print("config settings: %d" % len(cfg))

    # --- JSON objects -----------------------------------------------------
    objs, seen = [], set()
    for m in re.finditer(rb'\{"[A-Za-z][^\x00]{10,8000}?\}', data):
        try:
            o = json.loads(m.group().decode("utf-8", "ignore"))
        except Exception:
            continue
        k = json.dumps(o, sort_keys=True)
        if k not in seen:
            seen.add(k)
            objs.append(o)
    print("json objects   : %d" % len(objs))

    # --- strings ----------------------------------------------------------
    strings = sorted({s.decode("ascii", "ignore")
                      for s in re.findall(rb"[\x20-\x7e]{8,}", data)})
    print("distinct strings: %d" % len(strings))

    # --- system coverage --------------------------------------------------
    print("\nsystem coverage in capture:")
    cov = {}
    for name, pats in sorted(SYSTEM_MARKERS.items()):
        n = sum(len(re.findall(p, data)) for p in pats)
        cov[name] = n
        print("  %-18s %s %d" % (name, "YES" if n else "no ", n))

    with io.open(os.path.join(out, "capture-strings.txt"), "w",
                 encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(strings))
    with io.open(os.path.join(out, "capture-json.json"), "w",
                 encoding="utf-8", newline="\n") as fh:
        json.dump(objs, fh, indent=1, ensure_ascii=False)
    import csv
    with io.open(os.path.join(out, "server-config.csv"), "w",
                 encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["key", "value", "width_bytes"])
        w.writerows(cfg)
    print("\nwrote capture-strings.txt, capture-json.json, server-config.csv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
