# Agent Experience Notes

## Portable Toolkit

### tcsh Testing

- `tcsh -c "..."` is non-interactive, so `$?prompt` is false and the script exits at the guard. Use `tcsh -i` or pipe commands to test interactive behavior.
- tcsh has no functions. Use wrapper scripts (written to `/tmp`) for complex logic like AppImage lazy extraction.

### AppImage / FUSE

- Check FUSE with `fusermount --version`, not `fusermount3` (older systems only have fusermount v2).
- `--appimage-extract` creates `squashfs-root/` relative to CWD. Always `cd` to the target directory first.
- Extracted nvim binary is at `squashfs-root/usr/bin/nvim`.

### EDITOR Env Var

- Setting `EDITOR=nvim` when nvim is only an alias (not on PATH) doesn't work for external programs like `git commit`. Always set EDITOR to a full executable path.
- For FUSE case: set to the AppImage path directly.
- For no-FUSE case: generate a wrapper script in `/tmp` and set EDITOR to its path.
