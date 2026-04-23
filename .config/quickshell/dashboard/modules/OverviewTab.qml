// OverviewTab.qml — Calendar + User Info + System Stats
//
// Grid layout matching DMS style:
//   Calendar (top, full width)
//   User Info (bottom-left) + System Stats (bottom-right)

import QtQuick
import "./components"

Item {
    id: root

    required property var colors
    signal close()

    Column {
        anchors.fill: parent
        spacing: 12

        // Calendar (top ~55%)
        CalendarGrid {
            width: parent.width
            height: parent.height * 0.55
            colors: root.colors
        }

        // Bottom row: User Info + System Stats
        Row {
            width: parent.width
            height: parent.height * 0.45 - 12
            spacing: 12

            UserInfoCard {
                width: parent.width * 0.45 - 6
                height: parent.height
                colors: root.colors
            }

            SystemStatsCard {
                width: parent.width * 0.55 - 6
                height: parent.height
                colors: root.colors
            }
        }
    }
}
