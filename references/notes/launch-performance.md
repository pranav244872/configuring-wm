# Launch Performance on a Spinning Disk

Why Firefox and kitty felt slow to start, what was changed, and what was
deliberately *not* changed. Verified on this machine 2026-10-15.

Back to [notes index](README.md) - [docs index](../README.md)

## The machine this applies to

- **No SSD.** `sda` is a Seagate ST1000LM035, 2.5" **mechanical** drive,
  `rotational=1`, 931 GB. Everything cold is 100 % seeks.
- 7.5 GiB RAM, `sda` scheduler already `[bfq]`, `read_ahead_kb` already 8192.
  Both were correct already — don't "fix" them.

**No software change makes an HDD fast.** These changes get "noticeably slow"
to "acceptable". An SSD is the only thing that makes it fast.

## Diagnosis

| Finding | Evidence |
|---|---|
| Firefox held **4.4–5.2 GiB** across 15–17 processes | 3.6 GiB of it in 8+ **`Isolated Web Context`** processes = Fission site isolation, one content process per site |
| RAM exhausted, page cache squeezed | 345–963 MiB free, PSI `full avg10=0.52 %` (real stalling, not critical) |
| **28 MB read at every Firefox start** | `security_state/` in the profile, for cert/OCSP — *and* it blocks first paint on a network round-trip |
| kitty cold start re-reads font data | 2.5 MB Nerd Font + fontconfig cache scan across **120 installed fonts** |

Chain: Firefox's process explosion → RAM exhausted → page cache evicted →
next launch re-reads from spinning disk.

## Changes applied (all user-level, no sudo, no reboot)

**kitty** — `--single-instance --instance-group shell` on the terminal bind in
`~/.config/hypr/modules/keybinds.lua`.

⚠️ **`single_instance` is NOT a kitty config key.** Putting it in `kitty.conf`
makes kitty print `Ignoring unknown config key: single_instance`. Verified
against the **v0.49.2 source**: it is declared in
`kitty/simple_cli_definitions.py` as `type=bool-set` (CLI-only, alongside
`instance_group`), and has **zero** occurrences in `kitty/config.py`. Only the
`-1` / `--single-instance` CLI flag works. `kitty.conf` carries a comment
saying so.

**Firefox** — `~/.config/mozilla/firefox/<profile>/user.js`:
```js
user_pref("dom.ipc.processCount", 4);          // default ~8 on this CPU
user_pref("fission.autostart", false);         // pinned off
user_pref("security.OCSP.enabled", false);      // drops the 28 MB read + network stall
user_pref("security.remote_settings.crlite_filters.enabled", false);
```
Use **`user.js`, not `prefs.js`** — Firefox rewrites `prefs.js` on exit and
would clobber live edits, but re-applies `user.js` at every start.

**Rollback:** delete `user.js`; revert the one line in `keybinds.lua`. The
original `prefs.js` backup is `prefs.js.bak-20261015`.

## Swap is already correct — do NOT "fix" it

Tempting and **wrong**: enabling `zswap`.

- Swap device is `/dev/zram0`, 3.7 GiB, **1.9 GiB in use**, RAM-backed and
  compressed (zstd/lz4). **There is no disk swap, and `vmstat` shows
  `si=0 so=0`** — nothing is being paged to the spinning disk at all.
- `zswap` is a *front cache* that compresses pages **before** they reach a swap
  device. Its device is already zram, which **already compresses**. Stacking
  them is double compression; the kernel documents using one or the other.
- `vm.swappiness` was left at **60**. Raising it just burns CPU on compression
  for no gain when nothing spills to disk.

## Verify after a Firefox restart

```bash
ps -eo rss,comm | awk '$2 ~ /firefox|Web|Privileged|RDD|Isolated/ {s+=$1; n++} END{printf "%d procs, %.0f MiB\n", n, s/1024}'
free -m | awk 'NR==2{printf "free=%s buff/cache=%s\n",$4,$6}'
```

Expect fewer processes and less total RSS, with `buff/cache` growing — that
cache growth *is* the speedup for the next cold start.
