# GitLab Flow — Kurzreferenz

Zweck: Kurz und sichtbar dokumentieren, wie im Projekt Branching, Merge-Requests und Deploys ablaufen sollen.

## Ziele
- Einheitliche Branch-Namen und Workflow
- Klare Regeln für Merge-Requests (MR)
- CI/CD zuverlässig und reproduzierbar
- Schutz von `main`/`production`

## Branch-Konventionen
- `main` / `master` — Standard-Integrations-Branch (stabil)
- `production` — Branch, der deployed wird (falls getrennt)
- `feature/*` — neue Features (z. B. `feature/sync-ui`)
- `hotfix/*` — dringende Bugfixes für Produktion
- `bugfix/*` — reguläre Bugfixes
- `release/*` — Release-Vorbereitung (optional)

Beispiele:
- `feature/obsidian-sync`
- `hotfix/fix-db-connection`