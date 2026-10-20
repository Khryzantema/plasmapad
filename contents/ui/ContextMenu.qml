// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2

// A right-click menu built from a Kicker action list: an array of
// { text, icon, actionId, actionArgument, type, enabled, checkable, checked, subActions },
// where `type` can be "separator" or "title". It fades in and out and supports submenus.
QQC2.Menu {
    id: root

    // Anything the caller wants back with the chosen action (see actionTriggered).
    property var context: null

    // What the frosted-glass background blurs (see MenuBackground).
    property Item blurSource: null

    signal actionTriggered(var context, string actionId, var actionArgument)

    background: MenuBackground {
        menu: root
        source: root.blurSource
    }

    // Fade only: a scale animation would make the blurred background look misaligned until it ends.
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
    }

    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 110; easing.type: Easing.InCubic }
    }

    Component {
        id: itemComponent

        QQC2.MenuItem {
            property var entry: null

            onTriggered: root.actionTriggered(root.context, entry.actionId || "", entry.actionArgument)
        }
    }

    Component {
        id: subMenuComponent

        QQC2.Menu {
            id: subMenu

            background: MenuBackground {
                menu: subMenu
                source: root.blurSource
            }
        }
    }

    Component {
        id: separatorComponent

        QQC2.MenuSeparator {}
    }

    // Items are created with a null parent and handed to the menu with addItem()/addMenu(), which
    // takes ownership of them.
    function populate(menu, actions) {
        for (const action of actions) {
            if (action.type === "separator") {
                menu.addItem(separatorComponent.createObject(null));
            } else if (action.subActions) {
                const subMenu = subMenuComponent.createObject(null, { title: action.text });
                subMenu.icon.name = action.icon || "";
                populate(subMenu, action.subActions);
                menu.addMenu(subMenu);
            } else {
                const item = itemComponent.createObject(null, {
                    entry: action,
                    text: action.text || "",
                    enabled: action.type === "title" ? false : action.enabled !== false,
                    checkable: action.checkable === true,
                    checked: action.checked === true
                });
                item.icon.name = action.icon || "";
                menu.addItem(item);
            }
        }
    }

    // Shows the menu at the mouse position. `newContext` comes back in actionTriggered.
    function openFor(actions, newContext) {
        if (!actions || actions.length === 0) {
            return;
        }
        context = newContext;
        populate(root, actions);
        popup();
    }

    // Empties the menu once it has closed, ready for the next set of actions.
    onClosed: {
        while (count > 0) {
            const item = itemAt(0);
            if (item.subMenu) {
                removeMenu(item.subMenu);
            } else {
                removeItem(item);
            }
        }
    }
}
