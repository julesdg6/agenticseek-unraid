# agenticseek-unraid

Unraid Community Applications templates for [AgenticSeek](https://github.com/Fosowl/agenticSeek) — a 100% local, private AI assistant that can autonomously browse the web, write and execute code, and manage files.

![AgenticSeek Logo](https://raw.githubusercontent.com/Fosowl/agenticSeek/main/media/agentic_seek_logo.png)

## Prerequisites

[SearxNG](https://github.com/searxng/searxng) must be installed separately before setting up AgenticSeek. SearxNG is a free, self-hosted metasearch engine that AgenticSeek uses for private web searches.

Once installed, note the URL of your SearxNG instance (e.g. `http://192.168.1.100:8080`) — you will enter this as the **SearxNG URL** when configuring the container.

## Template

| Template | Docker Image | Description |
|---|---|---|
| [agenticseek.xml](templates/agenticseek.xml) | `ghcr.io/julesdg6/agenticseek-unraid:latest` | All-in-one container: React web UI + Python API backend + Valkey cache |

## Installation

### Via Unraid Community Applications

1. Install and configure a [SearxNG](https://github.com/searxng/searxng) instance (see [Prerequisites](#prerequisites) above).
2. In the Unraid UI go to **Apps** → search for **AgenticSeek**.
3. Install the **AgenticSeek** container.

### Manual template import

If the template is not yet in the Community Apps feed, run the following command in the Unraid terminal to download the template directly to your server:

```bash
mkdir -p /boot/config/plugins/dockerMan/templates-user && \
curl -o /boot/config/plugins/dockerMan/templates-user/agenticseek.xml \
  https://raw.githubusercontent.com/julesdg6/agenticseek-unraid/main/templates/agenticseek.xml
```

Then go to **Docker** → **Add Container** and the **AgenticSeek** template will be available in the template dropdown.

## Configuration

### Required settings

| Setting | Default | Notes |
|---|---|---|
| **SearxNG URL** | `http://YOUR-SEARXNG-IP:8080` | URL of your pre-installed SearxNG instance |
| **Provider Name** | `ollama` | `ollama`, `openai`, `deepseek`, `openrouter`, `google`, `anthropic`, etc. |
| **Provider Model** | `deepseek-r1:14b` | Model tag for your chosen provider |
| **Provider Server Address** | `host.docker.internal:11434` | Address of your Ollama / LM Studio / LLM server |
| **Backend URL** | `http://YOUR-SERVER-IP:7777` | **Must be set to your Unraid server's LAN IP** — see note below |

> **⚠️ Backend URL is required**
>
> `REACT_APP_BACKEND_URL` is embedded into the React frontend at dev-server
> startup time.  You **must** replace `YOUR-SERVER-IP` with your Unraid
> server's actual LAN IP address (e.g. `http://192.168.1.100:7777`) before
> starting the container.  If this value is left as the placeholder the UI
> will show *"System offline. Deploy backend first."*

### Using a local Ollama instance

If Ollama is running directly on the Unraid host (not in a container), set **Provider Server Address** to `host.docker.internal:11434`. The container has `--add-host=host.docker.internal:host-gateway` pre-configured so this will resolve correctly.

### Cloud LLM providers

Set the relevant API key in the container and change **Provider Name** accordingly:

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

All data is stored under `/mnt/user/appdata/agenticseek/` by default:

```
/mnt/user/appdata/agenticseek/
├── redis/          ← Valkey data
└── screenshots/    ← Browser screenshots saved by the agent

/mnt/user/data/agenticseek-workspace/
                    ← Files the AI agent can read and write
```

> **Note on the Appdata path**
>
> The Appdata path is mapped to `/app/userdata` inside the container, **not**
> `/app`.  The `/app` directory holds the Python application source code that
> is baked into the image; bind-mounting an empty host directory there would
> shadow the source files and prevent the backend from starting.

## Accessing the UI

Open your browser at **`http://[SERVER-IP]:3333`** after the container is running.

## Troubleshooting

### "System offline. Deploy backend first."

1. Make sure **Backend URL** (`REACT_APP_BACKEND_URL`) is set to your Unraid server's real LAN IP, e.g. `http://192.168.1.100:7777`.  A placeholder value will always show offline.
2. Confirm that **Backend Port** `7777` is exposed in the Unraid template (it is by default).
3. Check the container logs for backend startup errors:
   ```bash
   docker logs agenticseek
   ```

## Support

- Template issues: [github.com/julesdg6/agenticseek-unraid/issues](https://github.com/julesdg6/agenticseek-unraid/issues)
- AgenticSeek project: [github.com/Fosowl/agenticSeek](https://github.com/Fosowl/agenticSeek)
