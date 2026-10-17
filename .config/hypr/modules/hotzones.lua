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
-- Geometry: a zone is the outer `trigger_px` of the monitor. Touching the exact
-- outermost pixel is an instant "slam"; anywhere else the dwell timer applies.
-- Corners are `trigger_px` squares; edges skip `corner_margin_px` at both ends
-- and stay quiet where the monitor has a neighbour outside that edge.
--
-- Action strings are "<dispatcher>, <args>"; `exec` runs them through the shell.

hl.config({
    hotzone = {
        enabled         = true, -- master switch
        dwell_ms        = 400,  -- rest time in the zone before firing (0 = instant)
        trigger_px      = 12,   -- bezel thickness that counts as "in the zone"
        rearm_margin_px = 24,   -- travel out of a fired zone needed to re-arm it
        corner_margin_px = 10,  -- corner zones carve this out of neighbouring edges
        suppress_on_fullscreen = true,

        -- Right edge opens the session menu (PowerMenuHost; closes on Escape /
        -- click-away -- deliberately not on hover-out).
        right = { action = "exec, qs ipc call powermenu toggle" },
    },
})
