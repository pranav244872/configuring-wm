# Display and Brightness Notes

How the backlight behaves on this laptop and what the brightness script enforces.

Back to [notes index](README.md) - [docs index](../README.md)

## brightnessctl on this laptop

- Installed version is **0.5**, and `brightnessctl get` returns **raw sysfs
  units**, not a percentage: this laptop's backlight is `intel_backlight` with
  `max_brightness = 26666`, so `get` answers e.g. `13922` (≈52 %).
  Version 0.5 has **no percentage mode** — `-m` is `--machine-readable` there.
  Scale it yourself: `b=$(brightnessctl get); m=$(cat /sys/class/backlight/*/max_brightness | head -1);
  echo $(( b * 100 / m ))`.
- **The `-e <exponent>` curve is range-dependent.** The old config's `-e4` was
  clearly tuned for a 0–9600 panel; against 0–26666 a "5 %" press is a lie.
  Measured, starting from 60 %:

  | command | 4 presses down |
  |---|---|
  | `brightnessctl -e4 -n2 set 5%-` | 47 → 37 → 28 → 21 % |
  | `brightnessctl -e2 -n2 set 5%-` | 52 → 45 → 39 → 33 % |
  | `brightnessctl -n2 set 5%-` (linear, ours) | 55 → 50 → 45 → 40 % |

  So brightness keys "did nothing" after a few presses: they were slamming the
  panel to its kernel minimum. `-e4` is removed from all four binds.
- **The floor lives in `~/.config/hypr/scripts/brightness.sh`**
  (`sh <path> up|down [step%]`): down stops at **1 %**, up from 1 % jumps back
  to **5 %**, top clamps at 100 %. A script rather than a longer inline command
  keeps the four binds one-liners and puts the logic in one place; it prints the
  resulting percentage on stdout (handy when testing by hand).
- The panel can't represent 1 % steps near the bottom: raw 533 (2 %) stays 533
  however many times you ask for +1 %. Fine at normal levels (266 raw = 1 %).
- **Round, never truncate, when converting raw → percent.** `raw * 100 / max`
  makes a real 15 % read back as 14 %, and every subsequent step drifts by 1 %.
  Use `((raw * 100 + max / 2) / max)` — in the script and in the OSD probe.
- `brightness.sh` also has a `set <percent>` mode for the OSD slider (clamped
  to the same 1–100 range), so the slider and the keys share one code path.
