import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

// Searches nixpkgs through nixpkg.nu (nh search on both flake channels); Enter shows details in a floating terminal
Item {
    id: root

    property var pluginService: null
    property string trigger: "nx"

    signal itemsChanged()

    readonly property string script: Qt.resolvedUrl("nixpkg.nu").toString().replace("file://", "")
    readonly property string runner: Qt.resolvedUrl("run.sh").toString().replace("file://", "")
    // the backend's last failure ({what, message}) while searching or listing, shown as a line on top
    property var backendError: null
    property string pending: ""
    property string resultsQuery: ""
    property var results: []
    property var channels: ({ stable: "stable", unstable: "unstable" })
    property var installedList: null
    property real installedAt: 0
    property var updates: ({}) // attr -> newer version on its channel than flake.lock pins
    property real updatesAt: 0

    // DMS's default terminal (its setting, else $TERMINAL, else the first one installed); niri floats ghostty's app-id.
    // run.sh runs the action and, if it fails, offers the output to the agent through a notification.
    function terminal(args, mode) {
        const term = SessionData.resolveTerminal() || "xterm"
        const flags = term === "ghostty" ? ["--class=dev.nixpkgs.launcher", "-e"] : ["-e"]
        Quickshell.execDetached([term].concat(flags, ["sh", root.runner, mode || "run", term], args))
    }

    function agentName() {
        return ({ claude: "Claude", codex: "Codex", opencode: "OpenCode" })[pluginService?.loadPluginData("nixPackages", "agent", "claude")] || "the agent"
    }

    // parses a backend reply; a failure (or output that is not JSON, like a nu syntax error) becomes backendError
    function reply(what, text) {
        let out
        try {
            out = JSON.parse(text)
        } catch (e) {
            out = { error: "nixpkg.nu " + what + " did not answer with JSON:\n" + text }
        }
        backendError = out.error ? { what: "nixpkg.nu " + what, message: out.error } : null
        if (out.channels)
            channels = out.channels
        return out.error ? null : out
    }

    function withError(items) {
        // without nu the backend cannot answer at all, and the Missing line already says why
        if (!backendError || missing.includes("nu"))
            return items
        return [{
            name: "Plugin error: " + backendError.message.split("\n")[0],
            icon: "material:error",
            comment: "Enter: ask " + agentName() + " about it",
            action: "error",
            categories: ["Nix packages"],
            primaryAction: { name: "Ask " + agentName(), icon: "smart_toy", action: "execute" },
            _preScored: 3001
        }].concat(items)
    }

    function hint(text) {
        return {
            name: text,
            icon: "material:search",
            comment: "nh search on nixpkgs " + channels.stable + " and " + channels.unstable,
            action: "none",
            categories: ["Nix packages"],
            _preScored: 1000
        }
    }

    // "1.4.2 (unstable 1.5.2)", "10.11.11", or "unstable only: 2.0" (just the version once installed)
    function versions(p) {
        if (!p.stable)
            return !p.unstable ? "" : p.installed ? p.unstable : channels.unstable + " only: " + p.unstable
        if (!p.unstable || p.unstable === p.stable)
            return p.stable
        return p.stable + " (" + channels.unstable + " " + p.unstable + ")"
    }

    // packages marked from the context menu (right-click / Menu / F10 then Enter), applied in one rebuild. Only that
    // menu keeps the launcher open: DMS closes it after Enter or a Tab-panel action, whatever the plugin does
    property var selection: [] // [{attr, op: "stable" | "unstable" | "remove", pkg}]

    function selected(attr) {
        return selection.find(s => s.attr === attr)
    }

    function select(p, op) {
        selection = selection.filter(s => s.attr !== p.attr).concat([{ attr: p.attr, op: op, pkg: p }])
    }

    function deselect(attr) {
        selection = selection.filter(s => s.attr !== attr)
    }

    function opLabel(s) {
        if (s.op === "remove")
            return "remove"
        return (s.pkg.installed ? "switch to " : "install (") + channels[s.op] + (s.pkg.installed ? "" : ")")
    }

    function other(list) {
        return list === "stable" ? "unstable" : "stable"
    }

    // " 1.2.3" when that list's version is known
    function ver(p, list) {
        return p[list] ? " " + p[list] : ""
    }

    // while something is selected: an Apply line, then the selected packages whatever the search, then the rest
    function withSelection(items) {
        if (selection.length === 0)
            return items
        const apply = {
            name: "Apply " + selection.length + (selection.length === 1 ? " change" : " changes"),
            icon: "material:done_all",
            comment: selection.map(s => s.attr + ": " + opLabel(s)).join(" · "),
            action: "apply",
            categories: ["Nix packages"],
            primaryAction: { name: "Apply", icon: "done_all", action: "execute" },
            _preScored: 2000
        }
        const pinned = selection.map((s, j) => Object.assign(toItem(s.pkg, 0), { _preScored: 1999 - j }))
        return [apply].concat(pinned, items.filter(it => !(it.pkg && selected(it.pkg.attr))))
    }

    function toItem(p, i) {
        const s = selected(p.attr)
        const up = p.installed ? updates[p.attr] : null
        return {
            name: p.attr,
            icon: s ? (s.op === "remove" ? "material:remove_circle" : p.installed ? "material:swap_horiz" : "material:add_circle") : up ? "material:upgrade" : p.installed ? "material:check_circle" : "material:package_2",
            comment: [s ? "selected: " + opLabel(s) : "", versions(p), up ? "update available: " + up : "", p.installed ? "installed (" + channels[p.installed] + ")" : "", p.description].filter(s => s).join(" · "),
            action: "show",
            pkg: p,
            categories: ["Nix packages"],
            primaryAction: { name: "Details", icon: "info", action: "execute" },
            _preScored: 999 - i // keep the backend's order
        }
    }

    // commands the plugin runs -> the package providing them
    readonly property var deps: ({ "nu": "nushell", "nh": "nh", "nix-search-tv": "nix-search-tv", "nvim": "neovim", "notify-send": "libnotify" })
    property var missing: []
    property real depsAt: 0

    // while commands are missing: a line on top that offers to install them
    function withMissing(items) {
        if (missing.length === 0)
            return items
        // the install runs nixpkg.nu, so nu can only be added by hand
        const stuck = missing.filter(c => c === "nu")
        return [{
            name: "Missing: " + missing.join(", "),
            icon: "material:warning",
            comment: stuck.length ? "Add " + stuck.map(c => deps[c]).join("") + " to raf-user.nix and rebuild, the plugin needs it to install anything"
                                  : "Enter: add " + missing.map(c => deps[c]).join(", ") + " to raf-user.nix and rebuild",
            action: stuck.length ? "none" : "deps",
            categories: ["Nix packages"],
            primaryAction: { name: "Install", icon: "download", action: "execute" },
            _preScored: 3000
        }].concat(items)
    }

    function getItems(query) {
        if (!depCheck.running && Date.now() - depsAt > 10000)
            depCheck.running = true
        // a channel moves at most a few times a day and nix re-fetches it hourly: no need to check often
        if (!updateCheck.running && Date.now() - updatesAt > 60000)
            updateCheck.running = true
        return withError(withMissing(withSelection(viewItems(query))))
    }
    function viewItems(query) {
        const q = (query || "").trim()
        if (q.length === 0) {
            // reload at most every few seconds: requestLauncherUpdate calls back in here
            if (!list.running && Date.now() - installedAt > 5000)
                list.running = true
            if (installedList === null)
                return [hint("Loading installed packages…")]
            const n = installedList.filter(p => updates[p.attr]).length
            const ups = n ? " · " + n + (n === 1 ? " update" : " updates") + " available" : ""
            return [hint(installedList.length + " installed" + ups + " · type to search nixpkgs")].concat(installedList.map(toItem))
        }
        if (q.length < 2)
            return [hint("Type a package name to search nixpkgs")]
        if (q !== pending) {
            pending = q
            debounce.restart()
        }
        if (resultsQuery !== q)
            return [hint("Searching for “" + q + "”…")]
        if (results.length === 0)
            return [hint("No packages found for “" + q + "”")]
        return results.map(toItem)
    }

    function executeItem(item) {
        if (item?.action === "show") {
            terminal(["show", item.pkg.attr])
        } else if (item?.action === "apply") {
            terminal(["apply"].concat(selection.map(s => s.op + ":" + s.attr)))
            selection = []
        } else if (item?.action === "error") {
            terminal([backendError.what, backendError.message], "ask-text")
        } else if (item?.action === "deps") {
            terminal(["apply"].concat(missing.map(c => "stable:" + deps[c])))
        }
    }

    function getContextMenuActions(item) {
        if (item?.action === "apply")
            return [{ icon: "clear_all", text: "Clear selection", action: () => root.selection = [] }]
        if (item?.action !== "show")
            return []
        const p = item.pkg
        const actions = []
        // The Tab panel closes the launcher after any action, which makes selecting pointless there, but DMS asks for
        // its list the same way as for the context menu: tell them apart by the caller's file in the call stack.
        // shortcut: relies on DMS's file name; if it is renamed, Tab shows the select entries again
        const tabPanel = (new Error().stack || "").includes("/ActionPanel.qml")
        // the select entries come first in the context menu: what F10 then Enter picks
        if (!tabPanel) {
            if (selected(p.attr)) {
                actions.push({ icon: "remove_done", text: "Deselect", action: () => root.deselect(p.attr) })
            } else if (p.installed) {
                actions.push({ icon: "remove_circle", text: "Select for removal", action: () => root.select(p, "remove") })
                actions.push({ icon: "swap_horiz", text: "Select to switch to " + channels[other(p.installed)] + ver(p, other(p.installed)), action: () => root.select(p, other(p.installed)) })
            } else {
                if (p.stable)
                    actions.push({ icon: "add_circle", text: "Select to install (" + channels.stable + ")", action: () => root.select(p, "stable") })
                if (p.unstable)
                    actions.push({ icon: "add_circle", text: "Select to install (" + channels.unstable + ")", action: () => root.select(p, "unstable") })
            }
        }
        // these leave the launcher for a terminal or browser, so close it
        if (p.installed) {
            actions.push({ icon: "delete", text: "Uninstall now", closeLauncher: true, action: () => terminal(["uninstall", p.attr]) })
            actions.push({ icon: "swap_horiz", text: "Switch to " + channels[other(p.installed)] + ver(p, other(p.installed)) + " now", closeLauncher: true, action: () => terminal(["install", p.attr, other(p.installed)]) })
            actions.push({ icon: "system_update_alt", text: "Update " + channels[p.installed] + (updates[p.attr] ? " now → " + updates[p.attr] : " now") + " (all its packages)", closeLauncher: true, action: () => terminal(["update", p.installed]) })
            actions.push({ icon: "edit", text: "Edit in raf-user.nix", closeLauncher: true, action: () => terminal(["edit", p.attr]) })
        } else {
            if (p.stable)
                actions.push({ icon: "download", text: "Install " + p.stable + " now (" + channels.stable + ")", closeLauncher: true, action: () => terminal(["install", p.attr, "stable"]) })
            if (p.unstable)
                actions.push({ icon: "new_releases", text: "Install " + p.unstable + " now (" + channels.unstable + ")", closeLauncher: true, action: () => terminal(["install", p.attr, "unstable"]) })
        }
        if (p.homepage)
            actions.push({ icon: "open_in_new", text: "Open homepage", closeLauncher: true, action: () => Qt.openUrlExternally(p.homepage) })
        actions.push({ icon: "content_copy", text: "Copy name", action: () => Quickshell.execDetached(["dms", "cl", "copy", p.attr]) })
        return actions
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: if (!search.running) root.startSearch()
    }

    function startSearch() {
        search.query = pending
        search.command = ["nu", script, "search"].concat(pending.split(/\s+/))
        search.running = true
    }

    Process {
        id: search
        property string query: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const out = root.reply("search " + search.query, text)
                root.results = out ? out.results : []
                root.resultsQuery = search.query
                PluginService.requestLauncherUpdate("nixPackages")
            }
        }
        // the query moved on while this search ran: run the newer one too
        onExited: if (root.pending !== query) root.startSearch()
    }

    Process {
        id: list
        command: ["nu", root.script, "installed"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = root.reply("installed", text)
                root.installedList = out ? out.results : (root.installedList || [])
                root.installedAt = Date.now()
                PluginService.requestLauncherUpdate("nixPackages")
            }
        }
    }

    Process {
        id: updateCheck
        command: ["nu", root.script, "updates"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.updates = JSON.parse(text)
                } catch (e) {}
                root.updatesAt = Date.now()
                PluginService.requestLauncherUpdate("nixPackages")
            }
        }
    }

    // sh, not nu: it has to work when nu is the thing missing
    Process {
        id: depCheck
        command: ["sh", "-c", "for c in \"$@\"; do command -v \"$c\" >/dev/null || echo \"$c\"; done", "sh"].concat(Object.keys(root.deps))
        stdout: StdioCollector {
            onStreamFinished: {
                const now = text.split("\n").filter(s => s)
                root.depsAt = Date.now()
                if (now.join() !== root.missing.join()) {
                    root.missing = now
                    PluginService.requestLauncherUpdate("nixPackages")
                }
            }
        }
    }
}
