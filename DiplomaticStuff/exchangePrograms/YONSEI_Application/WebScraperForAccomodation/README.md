# Yonsei Housing Application Bot

Questo progetto automatizza il login al portale Yonsei e la compilazione della domanda dormitorio seguendo il PDF nella cartella.

Dal PDF: il termine `2026-FALL [SK Global & Int'l House]` diventa disponibile il **2 giugno 2026 alle 10:00 KST**, cioè **2 giugno 2026 alle 03:00 in Italia/Roma (CEST)**.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
playwright install chromium
cp config.example.json config.json
```

Poi modifica `config.json` con credenziali e dati dell'application.

## Login di prova

Esegui una volta:

```bash
python dorm_application_bot.py --setup-login
```

Si apre Chromium. Fai login manualmente, cambia password se il portale lo chiede, poi nella barra Playwright premi Resume. Lo script salva `storage_state.json`.

## Prova senza submit

```bash
python dorm_application_bot.py --dry-run
```

Lo script compila e si ferma prima del submit.

## Esecuzione il giorno dell'apertura

Avvialo qualche minuto prima delle 03:00:

```bash
python dorm_application_bot.py
```

Di default entra 10 minuti prima, aspetta le 03:00 Europe/Rome, seleziona il termine appena appare e compila i campi.

Per submit completamente automatico:

```bash
python dorm_application_bot.py --auto-submit
```

Lascia il browser visibile: se il portale mostra CAPTCHA, cambio password, pop-up imprevisti o conferme non standard, dovrai intervenire manualmente.
