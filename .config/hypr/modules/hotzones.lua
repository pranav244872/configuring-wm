--------------------
----  HOTZONES  ----
--------------------

-- Native edge/corner hot zones (fork feature): rest the cursor against a bezel
-- for `dwell_ms` and a dispatcher fires. Implemented in the fork's InputManager
-- -> HotZoneManager, not as a plugin.
--
-- `enabled` is the MASTER switch -- the runtime API can only turn it further off
-- (isActive = enabled AND runtime flag). Edit it to arm/disarm; the config
-- reloads live, so no restart is needed.
--
-- Geometry: a zone is the outer `trigger_px` of the monitor, and the cursor has
-- to rest there for `dwell_ms`. `slam` (off here) would let a *corner* fire
-- instantly on the exact outermost pixel. Corners are `trigger_px` squares; edges
-- skip `corner_margin_px` at both ends and stay quiet where the monitor has a
-- neighbour outside that edge.
--
-- Action strings are "<dispatcher>, <args>"; `exec` runs them through the shell.

hl.config({
    hotzone = {
        enabled         = true, -- master switch
        dwell_ms        = 300, -- rest time in the zone before firing (0 = instant)
        slam            = false, -- corners fire instantly on the exact bezel pixel
        trigger_px      = 12,   -- bezel thickness that counts as "in the zone"
        rearm_margin_px = 24,   -- travel out of a fired zone needed to re-arm it
        corner_margin_px = 10,  -- corner zones carve this out of neighbouring edges
        suppress_on_fullscreen = true,

        -- Right edge opens the session menu (PowerMenuHost; closes on Escape /
        -- click-away -- deliberately not on hover-out).
        right = { action = "exec, qs ipc call powermenu toggle" },

        -- Bottom edge opens the dashboard (network first; bluetooth/audio/night
        -- light follow). Closes on Escape / click-away.
        bottom = { action = "exec, qs ipc call dashboard toggle" },

        -- Bottom-right corner opens the wallpaper carousel. Corners win over
        -- the right/bottom edges, so the power menu and the dashboard keep
        -- their own zones. The dashboard is closed first: both are bottom
        -- sheets, and two of them stacked reads as a bug.
        --
        -- Come at the corner directly (diagonally). The dwell counts residence,
        -- not rest: a slow slide *along* the bottom edge spends its 300ms in the
        -- dashboard's zone first, and once that sheet is up its exclusive focus
        -- suppresses every zone, so the corner never fires. Verified
        -- 2026-10-19 -- deliberate, not a bug we can fix from config.
        bottomright = { action = "exec, qs ipc call dashboard close; qs ipc call wallpaper toggle" },
    },
})
