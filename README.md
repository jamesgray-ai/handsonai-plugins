# Hands-on AI Plugin

The Hands-on AI plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — agents and skills from [handsonai.info](https://handsonai.info). One plugin, one install, three categories of work.

## What's Inside

**1 agent + 13 skills** scoped to a single coherent purpose: design, build, and document AI workflows.

| Category | Components |
|---|---|
| **Business-First AI Framework** | `framework-orchestrator` agent + 7 skills (`analyze`, `deconstruct`, `design`, `build`, `test`, `run`, `improve`) |
| **AI Registry** | 4 skills (`naming-workflows`, `writing-workflow-sops`, `writing-process-guides`, `registering-building-blocks`) |
| **Agentic Coding** | 2 skills (`writing-vision-briefs`, `writing-feature-prds`) |

## Installation

### Add the marketplace

Register this marketplace so your tool knows where to find the plugin. You only need to do this once.

**Claude Code / Cursor / VS Code:**

```
/plugin marketplace add jamesgray-ai/handsonai-plugins
```

**Cowork:** Click **+** > **Add plugins...** > **Add by URL** and enter `https://github.com/jamesgray-ai/handsonai-plugins.git`

### Install the plugin

```
/plugin install handsonai@handsonai
```

## Skill ZIP Downloads (for non-plugin platforms)

ChatGPT, M365 Copilot, Cursor, Codex CLI, Gemini CLI, and other tools that don't use the plugin format can still use the skills. Download individual skill ZIPs from [GitHub Releases](https://github.com/jamesgray-ai/handsonai-plugins/releases/latest).

## Migrating from the old plugins

This plugin replaces the previous four-plugin layout (`business-first-ai`, `ai-workflow-examples`, `ai-registry`, `agentic-coding`). One-time migration:

```
/plugin uninstall business-first-ai@handsonai
/plugin uninstall ai-workflow-examples@handsonai
/plugin uninstall ai-registry@handsonai
/plugin uninstall agentic-coding@handsonai
/plugin install handsonai@handsonai
```

Component names are unchanged — only the namespace prefix moved. `/business-first-ai:analyze` becomes `/handsonai:analyze`, etc.

The example agents and skills that used to live in `ai-workflow-examples` (executive writing, HBR-style editorial review, vendor-specific researchers, meeting prep) have moved to the [Example Gallery](https://handsonai.info/use-cases/example-gallery/) on the docs site as study material to copy and customize.

## Transparency & Security

Every file in this repository is **plain-text Markdown** — there is no compiled code, no executable scripts, and no hidden logic. You can read exactly what instructions your AI receives before you install anything.

The plugin contains only Markdown instruction files. There are no MCP servers, no external network calls, and no code execution beyond what your AI tool provides natively.

> [!CAUTION]
> Anthropic recommends reviewing any plugin before installing it: *"Make sure you trust a plugin before installing it. Anthropic does not control what files or software are included in plugins and cannot verify that they work as intended."*

## Structure

```
.claude-plugin/
  marketplace.json          # Marketplace manifest
plugins/
  handsonai/
    .claude-plugin/
      plugin.json           # Plugin metadata
    agents/                 # Agent definitions (.md)
    skills/                 # Skill directories (SKILL.md + references/)
    registries/             # Platform compatibility registry
```

## Documentation

- [The Hands-on AI Plugin](https://handsonai.info/use-the-playbook/build/handsonai/) — full component descriptions and usage examples
- [Using Plugins](https://handsonai.info/use-the-playbook/build/using-plugins/) — installation, usage, and troubleshooting
- [Example Gallery](https://handsonai.info/use-cases/example-gallery/) — agents, skills, and prompts to copy and customize
- [Plugin Documentation](https://code.claude.com/docs/en/plugins) — official plugin format reference
