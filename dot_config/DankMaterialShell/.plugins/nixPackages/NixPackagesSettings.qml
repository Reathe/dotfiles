import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "nixPackages"

    StringSetting {
        settingKey: "trigger"
        label: "Trigger"
        description: "What to type in the launcher to search nixpkgs, followed by the package name."
        placeholder: "nx"
        defaultValue: "nx"
    }

    SelectionSetting {
        id: agent
        settingKey: "agent"
        label: "Agent for errors"
        description: "When an action fails, a notification offers to open this coding agent in the dotfiles repo with the error."
        options: [
            { label: "Claude Code", value: "claude" },
            { label: "Codex", value: "codex" },
            { label: "OpenCode", value: "opencode" },
            { label: "Custom command", value: "custom" }
        ]
        defaultValue: "claude"
    }

    StringSetting {
        visible: agent.value === "custom"
        settingKey: "customAgent"
        label: "Custom agent command"
        description: "Run in the repo with the prompt as its last argument, e.g. \"aider --message\"."
        placeholder: "my-agent --prompt"
        defaultValue: ""
    }
}
