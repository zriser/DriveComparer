# Drive Comparer

A WPF tool for comparing two folders / drives on Windows. Finds files missing in the target, size or hash mismatches, and optionally extras in the target. Can copy missing files across.

## Running

Use **Windows PowerShell 5.1** (`powershell.exe`), not PowerShell 7 — the script depends on WPF / WinForms.

### 1. From a PowerShell terminal (recommended)

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\zacha\Documents\AI\DriveComparer\DriveComparer.ps1"
```

`-ExecutionPolicy Bypass` applies to that single invocation only and does not change any system setting.

### 2. Right-click the script

In File Explorer, right-click `DriveComparer.ps1` → **Run with PowerShell**. If Windows blocks it with an execution-policy error, use option 1 instead.

### 3. Desktop shortcut (for repeat use)

Right-click the Desktop → **New → Shortcut**, then paste the command from option 1 as the target. Name it "Drive Comparer".

## Options

- **Two-way compare** — also reports files that exist in the target but not the source.
- **Verify with SHA256** — compares file contents, not just sizes. Slower on large trees.
- **Skip hidden files** — ignores files with the Hidden attribute.
- **Copy missing to target** — after the compare, copies any source-only files into the target, preserving the folder structure.

## Notes

- Size is always checked before hashing, so SHA256 only runs when sizes match. Mismatched sizes are reported immediately.
- Long-running compares can be cancelled mid-flight — the UI stays responsive.
- Use the **Save Results** button to dump the output pane to a text file.
