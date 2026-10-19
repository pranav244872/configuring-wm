// Shared lock state, so the shell's surfaces can tell that the session is
// locked.
//
// They need it because the compositor does *not* suppress our hot zones while
// the session is locked: HotZoneManager::isSuppressed() tests
// `g_pInputManager->isLocked()`, which in this codebase means "a pointer
// constraint is active" (a game holding the cursor), not "the session is
// locked". Resting on an edge while locked therefore still runs its action --
// verified 2026-10-19, the bottom-right corner opened the wallpaper picker
// behind the lock, and it was still open after unlocking. Keybinds *are*
// blocked by the compositor, so the hot zones are the only leak.
//
// Hosts therefore refuse to open while locked, and close when a lock starts.
pragma Singleton

import QtQuick

QtObject {
    id: root

    property bool locked: false
}
