import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Keyboard pill: niri layout name, with an icon showing the kanata layer.
// Needs kanata's TCP server (services.kanata.keyboards.<kb>.port on NixOS).
PluginComponent {
    id: root

    property string host: pluginData.host ?? "127.0.0.1"
    property int port: pluginData.port ?? 5829
    property string activeLayer: ""
    readonly property string layout: NiriService.getCurrentKeyboardLayoutName()

    pillClickAction: () => NiriService.cycleKeyboardLayout()

    // "English (US)" -> "en-US", "Armenian (phonetic)" -> "hy", "English (US, intl., with dead keys)" -> "intl".
    // shortcut: tiny language map covering this machine's layouts; extend it when adding a layout.
    function layoutLabel(name) {
        if (name.includes("intl"))
            return "intl";
        const m = name.match(/^(\S+)(?: \(([^,)]+))?/);
        if (!m)
            return name;
        const code = ({ "armenian": "hy" })[m[1].toLowerCase()] ?? m[1].slice(0, 2).toLowerCase();
        return m[2]?.length <= 3 ? `${code}-${m[2]}` : code;
    }

    // Quickshell's Socket is unix-only, so read kanata's JSON lines via bash /dev/tcp; it sends the current layer on connect.
    Process {
        id: client
        running: true
        command: ["bash", "-c", `exec cat </dev/tcp/${root.host}/${root.port}`]
        stdout: SplitParser {
            onRead: data => {
                const msg = JSON.parse(data);
                root.activeLayer = msg.LayerChange?.new ?? root.activeLayer;
            }
        }
        onExited: root.activeLayer = ""
    }

    // Reconnect: kanata restarts on every rebuild and may start after DMS.
    Timer {
        interval: 3000
        running: !client.running
        onTriggered: client.running = true
    }

    component LayerIcon: DankIcon {
        // house = home-row mods on, plain keyboard = other layer, dimmed = kanata unreachable.
        name: root.activeLayer === "homerow" ? "home" : "keyboard"
        size: root.iconSize
        color: root.activeLayer === "homerow" ? Theme.primary : root.activeLayer ? Theme.widgetTextColor || Theme.surfaceText : Theme.surfaceVariantText
    }

    component LayoutText: StyledText {
        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
        color: Theme.widgetTextColor || Theme.surfaceText
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            LayerIcon {
                anchors.verticalCenter: parent.verticalCenter
            }

            LayoutText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.layoutLabel(root.layout)
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 2

            LayerIcon {
                anchors.horizontalCenter: parent.horizontalCenter
            }

            LayoutText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.layoutLabel(root.layout).slice(0, 2)
            }
        }
    }
}
