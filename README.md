# agenticseek-unraid

Unraid Community Applications templates for [AgenticSeek](https://github.com/Fosowl/agenticSeek) — a 100% local, private AI assistant that can autonomously browse the web, write and execute code, and manage files.

![AgenticSeek Logo](https://raw.githubusercontent.com/Fosowl/agenticSeek/main/media/agentic_seek_logo.png)

## Prerequisites

[SearxNG](https://github.com/searxng/searxng) must be installed separately before setting up AgenticSeek. SearxNG is a free, self-hosted metasearch engine that AgenticSeek uses for private web searches.

Once installed, note the URL of your SearxNG instance (e.g. `http://192.168.1.100:8080`) — you will enter this as the **SearxNG URL** when configuring the backend container.

## Templates

| Template | Docker Image | Description |
|---|---|---|
| [agenticseek-redis.xml](templates/agenticseek-redis.xml) | `valkey/valkey:8-alpine` | Valkey (Redis-compatible) cache — **start first** |
| [agenticseek-backend.xml](templates/agenticseek-backend.xml) | `ghcr.io/julesdg6/agenticseek-backend:latest` | Python API backend |
| [agenticseek-frontend.xml](templates/agenticseek-frontend.xml) | `ghcr.io/julesdg6/agenticseek-frontend:latest` | React web UI |

## Installation

### Via Unraid Community Applications

1. Install and configure a [SearxNG](https://github.com/searxng/searxng) instance (see [Prerequisites](#prerequisites) above).
2. In the Unraid UI go to **Apps** → search for **AgenticSeek**.
3. Install the three containers **in order**:
   1. **AgenticSeek-Redis** — cache store (no UI)
   2. **AgenticSeek-Backend** — AI agent API
   3. **AgenticSeek-Frontend** — web interface

### Manual template import

If the templates are not yet in the Community Apps feed, add this repository URL in **Apps → Settings → Template Repositories**:

```
https://github.com/julesdg6/agenticseek-unraid
```

## Configuration

### Required settings

| Container | Setting | Default | Notes |
|---|---|---|---|
| Backend | **SearxNG URL** | `http://YOUR-SEARXNG-IP:8080` | URL of your pre-installed SearxNG instance |
| Backend | **Provider Name** | `ollama` | `ollama`, `openai`, `deepseek`, `openrouter`, `google`, `anthropic`, etc. |
| Backend | **Provider Model** | `deepseek-r1:14b` | Model tag for your chosen provider |
| Backend | **Provider Server Address** | `host.docker.internal:11434` | Address of your Ollama / LM Studio / LLM server |
| Frontend | **Backend URL** | `http://[SERVER-IP]:7777` | Replace with your Unraid server's LAN IP |

### Using a local Ollama instance

If Ollama is running directly on the Unraid host (not in a container), set **Provider Server Address** to `host.docker.internal:11434`. The backend container has `--add-host=host.docker.internal:host-gateway` pre-configured so this will resolve correctly.

### Cloud LLM providers

Set the relevant API key in the backend container and change **Provider Name** accordingly:

| Provider | Environment variable |
|---|---|
| OpenAI | `OPENAI_API_KEY` |
| DeepSeek | `DEEPSEEK_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |
| Together AI | `TOGETHER_API_KEY` |
| Google Gemini | `GOOGLE_API_KEY` |
| Anthropic Claude | `ANTHROPIC_API_KEY` |
| HuggingFace | `HUGGINGFACE_API_KEY` |

## Default paths

All containers store their data under `/mnt/user/appdata/agenticseek/` by default:

```
/mnt/user/appdata/agenticseek/
├── redis/          ← Valkey data
└── screenshots/    ← Browser screenshots saved by the agent

/mnt/user/data/agenticseek-workspace/
                    ← Files the AI agent can read and write
```

## Accessing the UI

Open your browser at **`http://[SERVER-IP]:3000`** after all three containers are running.

## Support

- Template issues: [github.com/julesdg6/agenticseek-unraid/issues](https://github.com/julesdg6/agenticseek-unraid/issues)
- AgenticSeek project: [github.com/Fosowl/agenticSeek](https://github.com/Fosowl/agenticSeek)
