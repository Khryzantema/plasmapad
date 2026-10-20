// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.plasma5support as P5Support

// Finds the image currently used as the desktop wallpaper by running code/wallpaper.sh, and
// keeps it decoded in memory so the launcher can show it on the very first frame.
Item {
    id: root

    // Wallpaper as a file:// URL; empty until the first lookup finishes.
    property url url

    // Size the image is decoded at. It must match the size Backdrop requests, otherwise the
    // pixmap cache cannot be shared.
    property size imageSize: Qt.size(0, 0)

    readonly property string script: Qt.resolvedUrl("../code/wallpaper.sh").toString().replace("file://", "")

    // Looks the wallpaper up again. The size lets the script pick the closest aspect ratio when
    // the wallpaper is a package with several resolutions.
    function refresh(width, height) {
        const command = "sh '" + script + "' " + width + " " + height;
        executable.disconnectSource(command);
        executable.connectSource(command);
    }

    // Never shown: it only keeps the decoded image in the pixmap cache while the launcher is closed.
    Image {
        source: root.imageSize.width > 0 ? root.url : ""
        sourceSize: root.imageSize
        asynchronous: true
        visible: false
    }

    // The "executable" engine runs a command and reports its output once.
    P5Support.DataSource {
        id: executable

        engine: "executable"

        onNewData: (source, data) => {
            const path = (data["stdout"] || "").trim();
            if (path !== "") {
                root.url = "file://" + path;
            }
            disconnectSource(source);
        }
    }
}
