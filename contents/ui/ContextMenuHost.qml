// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// Two alternating context menus. Right-clicking another app while a menu is still open (or
// fading out) must show the new menu at once; reusing one menu would empty it when the old one
// finishes closing. So the new menu always opens in the other instance: it fades in while the old
// one fades out.
Item {
    id: root

    property Item blurSource: null

    // The menu that was opened last.
    property var last: second

    signal actionTriggered(var context, string actionId, var actionArgument)

    function openFor(actions, context) {
        const menu = last === first ? second : first;
        last.close();
        last = menu;
        menu.openFor(actions, context);
    }

    ContextMenu {
        id: first

        blurSource: root.blurSource

        onActionTriggered: (context, actionId, actionArgument) => root.actionTriggered(context, actionId, actionArgument)
    }

    ContextMenu {
        id: second

        blurSource: root.blurSource

        onActionTriggered: (context, actionId, actionArgument) => root.actionTriggered(context, actionId, actionArgument)
    }
}
