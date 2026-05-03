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
> Set `REACT_APP_BACKEND_URL` to your Unraid server's actual LAN IP address
> (e.g. `http://192.168.1.100:7777`) before starting the container.
> The container generates a `window.AGENTICSEEK_BACKEND_URL` runtime config
> file on every startup, so **changing this value and restarting the container
> is enough** — no image rebuild is needed.  If this value is left as the
> placeholder the UI will show *"System offline. Deploy backend first."*

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
4. Verify the runtime config file was generated correctly inside the container:
   ```bash
   docker exec agenticseek cat /frontend/public/runtime-config.js
   ```
   The output should show your server's LAN IP, not `localhost`.

### Queries fail with "Unable to get a response"

This usually means the frontend is calling the wrong backend URL.

1. Check the runtime config file (see step 4 above).
2. If it shows `localhost:7777`, the `REACT_APP_BACKEND_URL` variable is either
   not set or set to the placeholder value.  Update it to your server's LAN IP,
   then **restart** the container (a restart is enough — no rebuild needed).
3. Make sure the URL is reachable from your browser, not just from inside Docker.
   `localhost` in a browser means *your desktop*, not the Unraid server.

### Template values reset after clicking Edit in Unraid

Unraid's dockerMan fetches the default template from `TemplateURL` when you
edit a container or check for updates, which can overwrite your saved values.

The distributed template no longer includes a `TemplateURL` element, so fresh
installs are not affected.

If you installed the template before this fix (or manually placed a copy of the
template that still contains a `<templateurl>` line), remove it from your local
copy.  The filename depends on how the template was installed:

- **Installed via Community Applications** — Unraid saves the template as
  `my-AgenticSeek.xml`:

  ```bash
  sed -i '/<templateurl>/Id' \
    /boot/config/plugins/dockerMan/templates-user/my-AgenticSeek.xml
  ```

- **Manually imported** (e.g. using the `curl` command from this README) —
  the file keeps the name you used, typically `agenticseek.xml`:

  ```bash
  sed -i '/<templateurl>/Id' \
    /boot/config/plugins/dockerMan/templates-user/agenticseek.xml
  ```

If you also have a duplicate `agenticseek.xml` in the same directory with the
same `<Name>AgenticSeek</Name>`, remove it to avoid conflicts:

```bash
rm /boot/config/plugins/dockerMan/templates-user/agenticseek.xml
```

### AgenticSeek uses the wrong Ollama address (falls back to localhost)

The container automatically patches `config.ini` at startup from the
`PROVIDER_SERVER_ADDRESS` environment variable.  If the backend logs show
`127.0.0.1:11434` instead of the address you configured:

1. Verify the variable is set in the Unraid container settings.
2. The value may include an `http://` scheme — that is fine; the startup script
   strips it automatically (e.g. `http://192.168.1.64:11434` becomes
   `192.168.1.64:11434` in `config.ini`).
3. Check the container logs for `[start-backend]` lines at startup — they show
   the exact values written to `config.ini` and can confirm whether the variable
   was received correctly.

### Backend crash: "No work dir specified"

If the container logs show:

```
Exception: No work dir specified, please specify a work dir in .env file.
```

the `WORK_DIR` environment variable is not set.  The image sets a default of `/opt/workspace`, which matches the **Workspace Path** volume mapping in the template.  If you see this error, verify that the `WORK_DIR` variable is present in the container settings and set to the container-side path of your workspace volume (default: `/opt/workspace`).

## Support

- Template issues: [github.com/julesdg6/agenticseek-unraid/issues](https://github.com/julesdg6/agenticseek-unraid/issues)
- AgenticSeek project: [github.com/Fosowl/agenticSeek](https://github.com/Fosowl/agenticSeek)
