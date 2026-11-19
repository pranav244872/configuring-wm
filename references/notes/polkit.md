# Polkit: the Shell as the Authentication Agent

How `pkexec` and other polkit actions get a password prompt on this machine, and
the trap that verifying the feature uncovered. Read before touching
`modules/polkit/` or the polkit layer rule.

Back to [notes index](README.md) - [docs index](../README.md)

## Why it is in the shell

`hyprpolkitagent` used to be the session agent. It is a separate C++/hyprtoolkit
process (53 MiB RSS, 344 MiB peak here, plus `polkit-qt6` and
`hyprland-qt-support`), it cannot use our theme, and it is an ordinary window —
a screen share would capture the password dialog.

Quickshell 0.3.2 ships `Quickshell.Services.Polkit` (the Arch package links
`libpolkit-agent-1` and installs the QML module). `PolkitAgent` registers itself
with polkitd for the shell's logind session; no helper process, no D-Bus
activation. The package was removed on 2026-11-19 — the shell is the agent.

## One agent per session (proved)

Starting a second agent while hyprpolkitagent runs fails:

```
failed to register listener: GDBus.Error:org.freedesktop.PolicyKit1.Error.Failed:
An authentication agent already exists for the given subject
```

So replacing it means **stopping the unit and deleting the
`systemctl --user start hyprpolkitagent` autostart line** before the shell
starts. After that, a five-line `qs -p` preview registered (`registered=true`)
and `pkexec /bin/true` routed `org.freedesktop.policykit.exec` to it
(`active=true`, session set up for `pranav`).

## Files

| File | Role |
|---|---|
| `modules/polkit/PolkitService.qml` | singleton: owns `PolkitAgent`, exposes `flow`, `shown`, `failed`, `prompt`, `submit()`, `cancel()`, preselects the shell user's identity |
| `modules/polkit/PolkitHost.qml` | one full-screen `PanelWindow` per output, overlay layer, `Exclusive` keyboard focus while shown, focused monitor only, modal mask, IPC |
| `modules/polkit/PolkitContent.qml` | the Chaldea card: accent spine, action sentence, identity chips, password field, status line, CANCEL / AUTHENTICATE |

IPC: `qs ipc call polkit <state|isOpen|registered|cancel>`. `state` prints one
line (same idea as `idle state`) and is the first thing to read when a prompt
does not appear.

## QML shape

- A `QtObject` singleton has no default property in 0.3.2, so the agent **and**
  the flow `Connections` live in properties.
- `flow.message`, `actionId`, `identities`, `selectedIdentity`,
  `isResponseRequired`, `inputPrompt`, `responseVisible`,
  `supplementaryMessage`, `supplementaryIsError`, `failed`, `isCompleted` are the
  whole contract; `flow.submit(text)` and `flow.cancelAuthenticationRequest()`
  answer it.
- The request arrives before the surface maps, so focus is re-grabbed on a
  120 ms timer (same as the lock card). Exclusive focus plus the modal mask
  makes the dialog usable and blocks clicks into the app behind it.
- One window is created per screen (`Variants model: Quickshell.screens`, as in
  `hotcorners`) but only the focused monitor's copy is visible.
- `AuthFlow.failed` stays true for the whole flow ("failed at least once"), so
  the dialog keeps its own flag and clears it when the field is edited.

## Security

- **Never above the lock.** `shown` is `active && !LockState.locked`; a layer
  surface over the lock screen is a password-phishing target. The request waits
  for the unlock instead.
- **Never captured.** `windowrules.lua` applies `no_screen_share` to the
  `quickshell:polkit` namespace. Stronger than it looks: the fork's
  `shouldRenderContent()` skips the surface for *any* capture, so `grim` cannot
  see the dialog either — screenshots of the prompt come out empty. That is the
  feature working, not a rendering bug: with the rule on, a capture shows the
  plain desktop; with it off, the card and its 50 % scrim appear (a background
  patch measures 18.5 vs 10.6 mean luma).
- The password only goes through `flow.submit()`; nothing logs it, and the field
  clears on every exit path.

## The trap that cost 10 minutes: `pam_faillock`

The dialog can show `(N MINUTES LEFT TO UNLOCK)`. That text is not ours:
`pam_faillock.so` produces it, polkit's PAM conversation forwards it as
`flow.supplementaryMessage`, and the card renders it verbatim.

Arch's `/etc/pam.d/system-auth` loads `pam_faillock` with the defaults
**deny=3, unlock_time=600** (10 minutes). Three consecutive failed PAM auths lock
the **account**, not just polkit:

| Service | Affected |
|---|---|
| `pkexec` / polkit (`polkit-1` PAM stack) | yes |
| `sudo` | yes |
| the lock screen (`LockAuth` uses the `login` stack) | yes |

A few wrong passwords while testing therefore lock you out of the dialog you are
testing — and of `sudo` and the lock screen with it. The journal names it:

```
polkit-agent-helper-1: pam_faillock(polkit-1:auth): User pranav is temporarily
locked out due to 3 consecutive failed login attempts
```

Mitigation while a tally is active: hold the lock (`qs ipc call caffeine enable`)
so the session cannot lock during the window. A successful auth runs `authsucc`
and clears the tally; `faillock --user pranav` then prints no rows. Resetting
early needs root, which is itself locked out — waiting is the only path.

## Verification (2026-11-19)

| Check | Result |
|---|---|
| registration while hyprpolkitagent runs | fails: "agent already exists" |
| registration after stopping it | `registered=true` |
| request routing | `pkexec /bin/true` → `org.freedesktop.policykit.exec`, action + sentence in the card |
| wrong password | card stays, `AUTHENTICATION FAILED - TRY AGAIN`, field cleared, retry accepted |
| Escape | request cancelled, `pkexec`: "Request dismissed", dialog unmaps |
| capture | invisible in `grim` with the rule on, visible with it off |
| success | confirmed: card closes, `pkexec` exits 0, `faillock` tally cleared |
| package removal | `hyprpolkitagent`, `polkit-qt6`, `hyprland-qt-support` removed; no orphans; agent stays registered |

## References studied

- quickshell `src/services/polkit/` (module.md, the manual agent example,
  `listener.cpp`) — the API ground truth.
- DankMaterialShell `Services/PolkitService.qml` +
  `Modals/PolkitAuthSurfaceModal.qml` — identity preselection (polkit may default
  to another admin) and the synthetic failure that switching identities causes.
- end-4/dots-hyprland `services/PolkitService.qml` +
  `FullscreenPolkitWindow.qml` + `PolkitContent.qml` — per-screen overlay,
  `OnDemand` focus, prompt cleanup. Both end-4 and DMS use
  `Quickshell.Services.Polkit`; Caelestia ships no agent, Noctalia a C++ one.
