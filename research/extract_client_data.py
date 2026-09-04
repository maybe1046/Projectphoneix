"""Extract the server-relevant, non-art files out of the Ascension MPQs.

MPQEditor's /fp (full path) flag does not work in build 3.6.0.866, so extracting
with a wildcard flattens everything into one directory and collides files that
share a basename (every addon has a core.lua). Instead we group the wanted files
by their directory inside the archive and issue one extraction per
(archive, directory, extension), pointing the output at the matching directory
on disk. Structure is preserved and nothing collides.

Output layout keeps provenance rather than merging archives, because WoW patch
precedence means the same path can exist in several MPQs with different content:

    D:\\coa-extract\\<archive>\\<original path inside the archive>
"""

import io
import os
import subprocess
import sys
import collections

MPQEDITOR = r"D:\mpqeditor\x64\MPQEditor.exe"
DATA_DIR  = r"D:\Program Files\Ascension\resources\client\Data"
LISTS     = r"C:\temp\mpqlist"
OUT       = r"D:\coa-extract"

# Everything a server implementer needs; none of the art that makes up 99% of
# the bytes. .dbc is the data foundation, .lua/.xml/.toc are the Ascension
# addons and therefore the only readable description of the custom systems.
WANTED = (".dbc", ".lua", ".xml", ".toc", ".txt", ".sql", ".json")


def archive_path(name):
    for root, _, files in os.walk(DATA_DIR):
        for f in files:
            if os.path.splitext(f)[0].lower() == name.lower():
                return os.path.join(root, f)
    return None


def main():
    archives = sorted(os.listdir(LISTS))
    total_expected = 0
    plan = []          # (archive, mpq path, directory, extension, count)

    for arch in archives:
        lf = os.path.join(LISTS, arch, "(listfile)")
        if not os.path.exists(lf):
            continue
        mpq = archive_path(arch)
        if not mpq:
            print("  ! no archive found for", arch)
            continue

        groups = collections.defaultdict(int)
        for line in io.open(lf, encoding="utf-8", errors="replace"):
            f = line.strip().replace("/", "\\")
            if not f:
                continue
            ext = os.path.splitext(f)[1].lower()
            if ext in WANTED:
                groups[(os.path.dirname(f), ext)] += 1

        for (d, ext), n in sorted(groups.items()):
            plan.append((arch, mpq, d, ext, n))
            total_expected += n

    print("archives with wanted files: %d" % len({p[0] for p in plan}))
    print("extraction jobs           : %d" % len(plan))
    print("files expected            : %d" % total_expected)
    print()

    done = 0
    for i, (arch, mpq, d, ext, n) in enumerate(plan, 1):
        mask   = (d + "\\" if d else "") + "*" + ext
        target = os.path.join(OUT, arch, d) if d else os.path.join(OUT, arch)
        os.makedirs(target, exist_ok=True)
        subprocess.run([MPQEDITOR, "extract", mpq, mask, target],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       stdin=subprocess.DEVNULL, timeout=300)
        done += 1
        if done % 25 == 0 or done == len(plan):
            print("  %d/%d jobs" % (done, len(plan)), flush=True)

    actual = sum(len(fs) for _, _, fs in os.walk(OUT))
    print()
    print("expected %d files, extracted %d" % (total_expected, actual))
    return 0


if __name__ == "__main__":
    sys.exit(main())
