# Keyboard

**Status: ⬜ not started** — one known conflict, documented below.

## The problem: kitty grabs `ctrl+shift+<letter>`

Verified against the installed kitty 0.49 (`/usr/lib/kitty/kitty/options/definition.py`):

```
kitty_mod+b move_window_backward      kitty_mod+k scroll_line_up
kitty_mod+c copy_to_clipboard         kitty_mod+l next_layout
kitty_mod+e combine / open_url_hints  kitty_mod+n new_os_window
kitty_mod+f move_window_forward       kitty_mod+o pass_selection_to_program
kitty_mod+g show_last_command_output  kitty_mod+q close_tab
kitty_mod+h show_scrollback           kitty_mod+r start_resizing_window
kitty_mod+j scroll_line_down          kitty_mod+s paste_from_selection
kitty_mod+t new_tab                   kitty_mod+u kitten
                                       kitty_mod+v paste_from_clipboard
                                       kitty_mod+w close_window
```

`kitty_mod` = **ctrl+shift**. Consequence:

> Any Hyprland bind using `CTRL + SHIFT + <letter>` **never fires while kitty is
> focused** — kitty consumes it inside the terminal and the compositor never sees
> the key.

This is why our `CTRL + SHIFT + F` fake-fullscreen bind appears dead: kitty's own
`ctrl+shift+f` = *move window forward*. Inside kitty, keys go either to kitty or
to the running program — never up to the compositor.

## Current bindings affected

| Bind | Hyprland | In kitty |
|---|---|---|
| `CTRL+SHIFT+F` fake fullscreen | works only when a **non-kitty** window is focused (game, Moonlight stream) | move_window_forward |
| `CTRL+SHIFT+T` new tab w/ cwd | n/a (kitty-only key) | our override → `new_tab_with_cwd` ✓ |

## Options when we act on it

- Move fake fullscreen to a key kitty doesn't grab, e.g. `CTRL + ALT + F`,
  `F9`, or an unused `XF86` key.
- Keep `CTRL+SHIFT+F` as the Moonlight-oriented bind (it does work there) and add
  the new key as the everyday one.
- Or drop fake fullscreen entirely — `SUPER+W` covers normal use.
