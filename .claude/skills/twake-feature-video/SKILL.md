---
name: twake-feature-video
description: >-
  Petite vidéo de présentation (10 à 16 s, MP4 1080p + GIF) d'une nouvelle feature de Twake Chat React (twake-space-chat), en fausse interface animée avec le skill stageshow. Obligatoire à chaque mise en production sur ng (« mets la dev sur NG », « déploie sur ng », « passe la X.Y.Z sur ng ») : lister ce qui part, et faire une vidéo par nouvelle feature visible, jamais pour un bug fix. Aussi sur demande : « fais une vidéo de la feature X », « démo animée de … ».
---

# Vidéo de feature Twake Chat

> **Équipe mobile** : ce skill vient du flux Twake Chat React. Pour une feature de l'app mobile, la méthode est la même (fausse interface animée avec `stageshow`, 10 à 16 s, MP4 1080p) mais on reprend le style de l'app Flutter (couleurs, composants, textes de `lib/` et `assets/l10n/intl_en.arb`), en cadre téléphone, et la feature seule. Les chemins `~/Developer/...` ci-dessous sont ceux de Clément : l'atelier se recrée avec `cp -R .claude/skills/stageshow ~/Developer/twake-chat-stageshow && cd ~/Developer/twake-chat-stageshow && npm install`. Les exemples `twake-chat` et `twake-threads` ne sont que dans son atelier.
> Les vidéos des grosses features se postent sous la note de release dans le salon (skill `mobile-deploy`).

Consigne de Clément (2026-11-01) : à chaque passage de la dev sur ng, vérifier s'il y a de nouvelles features ; si oui, une petite vidéo de présentation par feature. Pas de vidéo pour les bug fix.

## 1. Au passage sur ng : trier ce qui part

1. Version en place sur ng : dernier commit `chore(twake-chat): deploy twake-space-chat X.Y.Z` dans `~/Developer/twp-lng-apps` (`git log -- configs/twake-chat/twake-chat-react/values.yaml`). Version qui part : le tag de la procédure ng (skill harbor-publish, « Instance ng »).
2. Liste : `cd ~/Developer/twake-space-chat && git fetch --tags && git log --oneline v<ancienne>..v<nouvelle>`, puis `gh pr view <n>` pour les PR dont le titre ne suffit pas. Les titres ne suivent pas tous Conventional Commits : juger au contenu.
3. Classer chaque PR :
   - **Feature** (vidéo) : une chose nouvelle que l'utilisateur voit ou fait (un écran, une action, un panneau, un réglage).
   - **Pas de vidéo** : correctif (`fix`, « Fix: », « no longer », comportement remis d'aplomb), perf, test, e2e, chore, lint, refactor, CI, dépendances, sécurité invisible.
   - Doute : demander à Clément en une ligne.
4. Montrer le tableau (PR, titre, feature ou non) et proposer les vidéos. Aucune feature : le dire et continuer le déploiement.

## 2. Faire la vidéo

Atelier : `~/Developer/twake-chat-stageshow` (copie du skill stageshow, `npm install` fait, paquet `@linagora/twake-icons` copié dans `node_modules`). Exemples Twake déjà faits, à copier comme point de départ :

| Exemple | Montre |
|---|---|
| `examples/twake-chat` | Liste des salons + salon : réponse tapée, coches lues, réponse qui sort des points de saisie |
| `examples/twake-threads` | Carte de fil (`ds/ThreadCard`) → fenêtre flottante (`ds/FloatingWindow`), réponse, carte à « 3 messages » |

`examples/twake-chat/twake-chat.css` porte la charte (Inter, `#006bd8`, primary.dark `#0157ad`, bulles 16 px, bulle à soi primaire 12 % sur blanc, fond `chat-bg-light.jpg`, vrai logo) : l'importer, ne pas la recopier.

1. Lire le code de la feature dans `~/Developer/twake-space-chat` (`src/ds/*`, `src/ui/*`, textes dans `src/locales/en.json`) : reprendre ses composants, tailles, textes et animations réels.
2. Suivre le skill stageshow (plan, poster, scénario de 3 à 5 temps, `compact` 380 px). Icônes : `@linagora/twake-icons` (composants SVG, `fill: currentColor`), Lucide seulement pour ce qui manque.
3. Serveur : `node node_modules/vite/bin/vite.js playground --config playground/vite.config.ts --port 5199 --strictPort` (le relancer après avoir ajouté un dossier d'exemple).
4. Contrôle : `node scripts/film.mjs "http://localhost:5199/?capture=<ex>" --select '#example' --at done --still --out shots/<ex>.png`, aussi avec `--width 390`. Lire l'image, corriger, refilmer. `--still` sans `--at` montre l'état initial, pas le poster.
5. Enregistrer et exporter :

```bash
SP=<scratchpad>; rm -rf $SP/v
EX=<ex> node ~/.claude/skills/twake-feature-video/scripts/rec.cjs 1920 1200 $SP/v <durée ms + 2500>
V=$(ls $SP/v/*.webm)
ffmpeg -y -loglevel error -ss 0.9 -i "$V" -vf "crop=1920:1080:0:0" -c:v libx264 -pix_fmt yuv420p -crf 20 -movflags +faststart out/<ex>-demo.mp4
ffmpeg -y -loglevel error -i out/<ex>-demo.mp4 -vf "fps=20,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4" out/<ex>-demo.gif
ffmpeg -y -loglevel error -i out/<ex>-demo.mp4 -vf "fps=1/1.6,scale=640:-1,tile=3x3" -frames:v 1 shots/<ex>-vstrip.png
```

6. Lire la planche `shots/<ex>-vstrip.png`, puis `open out/<ex>-demo.mp4`.
7. Écrire `examples/<ex>/REHEARSAL.md` : ce qui est repris de l'app, ce qui ne l'est pas.

## Pièges déjà vus

- `Roll` n'accepte que du texte (`text.slice is not a function` sinon).
- Glob de Vite figé : nouvel exemple = relancer Vite (« Unknown example »).
- `.ss-window__body` doit être en `display:flex` sinon la zone de saisie sort du cadre.
- Points de saisie → message : une seule bulle qui s'élargit (`interpolate-size`), pas un `Swap`.
- À l'envoi, poser `focus:false` dans le même `set` que la bulle (sinon le curseur de texte saute).
- Curseur au repos : sur une zone vide, jamais sur le texte qui porte l'histoire.
- Glyphes : taille paire dans un bouton pair (12, 14, 16), sinon demi-pixel.
- ffmpeg de Playwright absent : `npx playwright-core install ffmpeg`.

## Rendre compte

Chemins du MP4, du GIF et du dossier source, le scénario en 3 à 4 lignes, les écarts avec l'app. Hors passage sur ng, ne rien publier (salon, release notes) sans demande. Au passage sur ng, la publication fait partie de la procédure (harbor-publish, « Instance ng ») : note non technique puis vidéos des plus grosses features dans `#twake-chat-release-notes:linagora.com`, via le skill `release-notes` (`post-video.mjs`).
