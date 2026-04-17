#!/usr/bin/env bash
# ============================================================
#  5 Steps to AI Pro — Mac Setup Script
#  https://github.com/jeuner/5-steps-ai-pro
# ============================================================
set -euo pipefail

# ── Farben ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $*"; }
info() { echo -e "${BLUE}→${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
fail() { echo -e "${RED}✗ FEHLER:${NC} $*"; exit 1; }
step() { echo -e "\n${BOLD}${BLUE}━━━ $* ${NC}"; }

# ── Voraussetzungen prüfen ───────────────────────────────────
check_requirements() {
  step "System-Check"

  # macOS prüfen
  [[ "$(uname)" == "Darwin" ]] || fail "Dieses Script läuft nur auf macOS."
  ok "macOS erkannt: $(sw_vers -productVersion)"

  # Apple Silicon empfohlen
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    ok "Apple Silicon (${ARCH}) — optimale Voraussetzungen"
  else
    warn "Intel Mac erkannt. Lokale Modelle laufen deutlich langsamer als auf Apple Silicon."
    read -rp "Trotzdem fortfahren? [j/N] " confirm
    [[ "$confirm" =~ ^[jJyY]$ ]] || exit 0
  fi

  # RAM prüfen
  RAM_GB=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
  if (( RAM_GB >= 24 )); then
    ok "RAM: ${RAM_GB} GB — sehr gut für lokale Modelle"
  elif (( RAM_GB >= 16 )); then
    warn "RAM: ${RAM_GB} GB — reicht zum Testen, für große Modelle besser 24 GB+"
  else
    warn "RAM: ${RAM_GB} GB — eingeschränkt. Nur kleine Modelle empfohlen."
  fi

  # Xcode Command Line Tools
  if ! xcode-select -p &>/dev/null; then
    info "Installiere Xcode Command Line Tools..."
    xcode-select --install
    echo "Bitte Installation abwarten, dann Script neu starten."
    exit 0
  fi
  ok "Xcode Command Line Tools vorhanden"
}

# ── Schritt 1: Homebrew ──────────────────────────────────────
install_homebrew() {
  step "Schritt 1 — Homebrew"
  if command -v brew &>/dev/null; then
    ok "Homebrew bereits installiert ($(brew --version | head -1))"
    info "Aktualisiere Homebrew..."
    brew update --quiet
  else
    info "Installiere Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # PATH für Apple Silicon setzen
    if [[ "$ARCH" == "arm64" ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    ok "Homebrew installiert"
  fi
}

# ── Schritt 2: OpenCode ──────────────────────────────────────
install_opencode() {
  step "Schritt 2 — OpenCode (AI Terminal-Assistent)"
  if command -v opencode &>/dev/null; then
    ok "OpenCode bereits installiert ($(opencode --version 2>/dev/null || echo 'Version unbekannt'))"
  else
    info "Installiere OpenCode via npm..."
    # Node.js prüfen / installieren
    if ! command -v node &>/dev/null; then
      info "Node.js wird benötigt — installiere via Homebrew..."
      brew install node
    fi
    ok "Node.js: $(node --version)"
    npm install -g opencode-ai
    ok "OpenCode installiert"
  fi
  echo ""
  echo -e "  ${BOLD}Starten mit:${NC} opencode"
  echo -e "  ${BOLD}Docs:${NC}       https://opencode.ai"
}

# ── Schritt 3: Ollama (lokale Modelle) ───────────────────────
install_ollama() {
  step "Schritt 3 — Ollama (Lokale AI-Modelle)"
  if command -v ollama &>/dev/null; then
    ok "Ollama bereits installiert ($(ollama --version 2>/dev/null | head -1))"
  else
    info "Installiere Ollama..."
    brew install ollama
    ok "Ollama installiert"
  fi

  # Ollama-Dienst starten
  if ! pgrep -x ollama &>/dev/null; then
    info "Starte Ollama im Hintergrund..."
    brew services start ollama
    sleep 2
  fi
  ok "Ollama läuft"

  # Empfohlene Modelle
  echo ""
  echo -e "  ${BOLD}Empfohlene Modelle zum Starten:${NC}"
  echo -e "  • ollama pull gemma4:latest   (~9 GB, sehr stark, multimodal)"
  echo -e "  • ollama pull gemma3:4b       (~3 GB, schnell & gut)"
  echo -e "  • ollama pull mistral         (~4 GB, stark)"

  read -rp "  Soll gemma4:latest jetzt heruntergeladen werden? (~9 GB) [j/N] " pull_model
  if [[ "$pull_model" =~ ^[jJyY]$ ]]; then
    ollama pull gemma4:latest
    ok "gemma4:latest bereit"
  fi
}

# ── Schritt 4: OpenRouter ────────────────────────────────────
setup_openrouter() {
  step "Schritt 4 — OpenRouter (Alle Modelle, ein API-Key)"
  echo ""
  echo -e "  OpenRouter gibt dir Zugang zu ${BOLD}hunderten AI-Modellen${NC}"
  echo -e "  (Claude, GPT-4o, Gemini, Llama, Mistral u.v.m.)"
  echo -e "  Viele davon ${GREEN}kostenlos${NC}, bei Bedarf Guthaben aufladen."
  echo ""
  echo -e "  ${BOLD}1.${NC} Konto erstellen: ${BLUE}https://openrouter.ai${NC}"
  echo -e "  ${BOLD}2.${NC} API-Key generieren unter: Keys → Create Key"
  echo -e "  ${BOLD}3.${NC} Key in deine Tools eintragen (OpenCode, eigene Scripts etc.)"
  echo ""

  read -rp "  OpenRouter API-Key jetzt in ~/.zshrc speichern? [j/N] " save_key
  if [[ "$save_key" =~ ^[jJyY]$ ]]; then
    read -rsp "  API-Key eingeben: " or_key
    echo ""
    if [[ -n "$or_key" ]]; then
      echo "" >> ~/.zshrc
      echo "# OpenRouter API Key" >> ~/.zshrc
      echo "export OPENROUTER_API_KEY=\"${or_key}\"" >> ~/.zshrc
      ok "Key in ~/.zshrc gespeichert. Neu laden mit: source ~/.zshrc"
    else
      warn "Kein Key eingegeben — übersprungen"
    fi
  fi
}

# ── Schritt 5: DeerFlow (Agenten-System) ────────────────────
install_deerflow() {
  step "Schritt 5 — DeerFlow (Multi-Agent Research System)"
  echo ""
  echo -e "  DeerFlow ist ein ${BOLD}KI-Agenten-Framework${NC} von ByteDance."
  echo -e "  Mehrere Agenten arbeiten zusammen: Research, Analyse, Bericht."
  echo -e "  Ideal um zu verstehen wie moderne Agenten-Systeme funktionieren."
  echo ""

  # Python prüfen
  if ! command -v python3 &>/dev/null; then
    info "Installiere Python via Homebrew..."
    brew install python
  fi
  ok "Python: $(python3 --version)"

  # uv / pip
  if ! command -v uv &>/dev/null; then
    info "Installiere uv (schnelles Python-Paket-Tool)..."
    brew install uv
  fi
  ok "uv installiert"

  DEERFLOW_DIR="$HOME/ai-projects/deerflow"
  if [[ -d "$DEERFLOW_DIR" ]]; then
    ok "DeerFlow bereits unter $DEERFLOW_DIR vorhanden"
  else
    read -rp "  DeerFlow nach ~/ai-projects/deerflow klonen? [j/N] " clone_deer
    if [[ "$clone_deer" =~ ^[jJyY]$ ]]; then
      mkdir -p "$HOME/ai-projects"
      git clone https://github.com/bytedance/deer-flow.git "$DEERFLOW_DIR"
      cd "$DEERFLOW_DIR"
      uv sync
      ok "DeerFlow installiert in $DEERFLOW_DIR"
      echo -e "  ${BOLD}Starten mit:${NC} cd ~/ai-projects/deerflow && uv run python main.py"
    fi
  fi
}

# ── Zusammenfassung ──────────────────────────────────────────
summary() {
  echo ""
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  Setup abgeschlossen — Du bist bereit!  ${NC}"
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${BOLD}Was du jetzt tun kannst:${NC}"
  echo -e "  • ${BLUE}opencode${NC}              → AI-Coding-Assistent starten"
  echo -e "  • ${BLUE}ollama run gemma4:latest${NC} → Lokales Modell im Terminal"
  echo -e "  • ${BLUE}https://openrouter.ai${NC} → Alle Modelle ausprobieren"
  echo -e "  • ${BLUE}~/ai-projects/deerflow${NC} → Agenten-System erkunden"
  echo ""
  echo -e "  Viel Spaß auf deiner AI-Reise! 🚀"
  echo ""
}

# ── Main ─────────────────────────────────────────────────────
main() {
  clear
  echo -e "${BOLD}"
  echo "  ╔═══════════════════════════════════════╗"
  echo "  ║     5 Steps to AI Pro — Mac Setup     ║"
  echo "  ║     github.com/jeuner/5-steps-ai-pro  ║"
  echo "  ╚═══════════════════════════════════════╝"
  echo -e "${NC}"

  check_requirements
  install_homebrew
  install_opencode
  install_ollama
  setup_openrouter
  install_deerflow
  summary
}

main "$@"
