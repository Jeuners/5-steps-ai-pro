# 5 Steps to AI Pro — Mac Setup

Automatisches Setup-Script für den schnellen Einstieg in die AI-Entwicklung auf dem Mac.

## Was wird installiert?

| Schritt | Tool | Beschreibung |
|---|---|---|
| 1 | **Homebrew** | Paket-Manager für macOS |
| 2 | **OpenCode** | AI-Coding-Assistent im Terminal |
| 3 | **Ollama** | Lokale AI-Modelle (gemma4:latest empfohlen) |
| 4 | **OpenRouter** | Zugang zu 200+ Modellen (Claude, GPT-4o, Gemini…) |
| 5 | **DeerFlow** | Multi-Agent Research System von ByteDance |

## Voraussetzungen

- macOS 13+ (Ventura oder neuer)
- Apple Silicon empfohlen (M1/M2/M3/M4) — 16 GB RAM Minimum, **24 GB+ empfohlen**
- Internetverbindung

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/jeuner/5-steps-ai-pro/main/setup.sh | bash
```

Oder manuell:

```bash
git clone https://github.com/jeuner/5-steps-ai-pro.git
cd 5-steps-ai-pro
chmod +x setup.sh
./setup.sh
```

## Sicherheit

- Das Script prüft bei jedem Schritt ob das Tool bereits installiert ist
- Nichts wird ohne Bestätigung heruntergeladen (Modelle, DeerFlow-Clone)
- API-Keys werden nur lokal in `~/.zshrc` gespeichert — niemals übertragen
- Kein `sudo` ohne Notwendigkeit

## Nach dem Setup

```bash
# Lokales Modell im Terminal
ollama run gemma4:latest

# AI-Coding-Assistent
opencode

# Agenten-System
cd ~/ai-projects/deerflow
uv run python main.py
```

## Weiterführende Links

- [OpenRouter](https://openrouter.ai) — Alle Modelle, ein API-Key
- [Ollama](https://ollama.com) — Lokale Modelle
- [OpenCode](https://opencode.ai) — AI Terminal-Assistent
- [DeerFlow](https://github.com/bytedance/deer-flow) — Multi-Agent Framework
