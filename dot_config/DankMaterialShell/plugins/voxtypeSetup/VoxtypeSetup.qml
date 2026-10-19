import Quickshell
import "../voxtype"

// The upstream psyreactor/dms-voxtype widget, kept updatable by DMS; only the click is added
VoxtypeWidget {
    // niri floats this app-id
    pillClickAction: () => Quickshell.execDetached(["ghostty", "--class=dev.voxtype.configure", "-e", "voxtype", "configure"])
}
