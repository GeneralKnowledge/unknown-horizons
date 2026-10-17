# Community legacy save fixtures (optional)

Place donated `.sqlite` savegames here for Godot load matrix testing.

Each submission should include a one-line provenance file, e.g. `my_save.txt`:

```
filename: my_save.sqlite
uh_version: 2017.2
author: (optional)
license: GPL-2.0-or-later (must be compatible with repo)
notes: why this save is useful (large city, edge case, etc.)
```

Files are scanned by `development/godot/sqlite_fixture_matrix.py`. Treat untrusted saves as data-only; do not execute non-sqlite content.
