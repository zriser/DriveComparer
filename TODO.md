# Drive Comparer — TODO

Remaining ideas after the low-effort round + DataGrid.

## Bigger upgrades

- [ ] **Mirror mode** — delete extras in target, with a confirm dialog listing what will go. Destructive, so gate behind an explicit checkbox and a second confirmation.
- [ ] **Newer-wins sync mode** — compare by last-write time; copy whichever side is newer (either direction). Turns the tool into a basic bidirectional sync.
- [ ] **Parallel hashing** — `ForEach-Object -Parallel` (PS 7) or runspace pool (PS 5.1) for SHA256. Roughly Nx faster on SSDs when checksum mode is on.
- [ ] **Dry-run copy** — checkbox that reports what *would* be copied/deleted without touching the filesystem.

## Small polish

- [ ] Remember window size and position between runs (save to a small JSON alongside the script).
- [ ] CSV export alongside TXT — one row per result with columns for status, path, size, hash.
- [ ] Right-click a result row → **Open containing folder** (Explorer, with the file selected).
- [ ] Color-coded result rows — missing / different / extra in distinct foregrounds.
- [ ] Date-modified filter — only compare files modified since X.
- [ ] Pause button (distinct from cancel) — freeze the worker, resume later.
- [ ] Warn when a scan is about to enumerate more than N files (e.g. pointing at `C:\`).

## Maybe / out of scope

- [ ] Snapshot mode — store a scan result and diff against a later scan of the same tree (for incremental backups).
- [ ] Multiple source → target pairs in one run.
- [ ] Scheduled runs — probably better handled via Windows Task Scheduler.
