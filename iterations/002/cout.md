# Itération 002 — Coût (sponsor, tour 2, mesure partielle)

Source : `./dev cout` → `iterations/002/cout.json` (relevé à 12:34 UTC). `fin` est `null` : l'itération n'est pas close, les chiffres sont cumulés depuis le début (11:39:13 UTC).

## 1. Synthèse

| Indicateur | Valeur |
|---|---|
| Coût cumulé estimé (équivalent API) | **7,81 USD** (7,8130) |
| Durée écoulée | 54,7 min |
| Requêtes | 321 (103 Opus, 218 Haiku) |
| Boucles AOPR documentées | **0** — `observation.md` n'existe pas ; `iterations/002/policies/` est vide (aucun résultat de `./dev policies` archivé) |
| Critères constatés livrés | **0** — pas d'observation, recette client en cours (3 captures dans `client/`) |
| Coût par critère livré | **Non calculable** (dénominateur nul). Indicatif : 7,81 / 24 CA visés dans la table de couverture de la recette ≈ 0,33 USD par CA visé, non constaté |

## 2. Ventilation par modèle (recalculée avec `tools/sponsor/tarifs.json`)

| Modèle | Requêtes | Input | Output | Cache écriture | Cache lecture | Coût USD | Part |
|---|---|---|---|---|---|---|---|
| claude-opus-5-5 | 103 | 206 | 212 543 | 405 457 | 5 049 029 | 7,2888 | 93,3 % |
| claude-haiku-5-5 | 218 | 436 | 459 855 | 1 151 330 | 15 028 917 | 0,5242 | 6,7 % |

Décomposition :

- Opus : output 4,25 USD (58 %), écriture de cache 2,03 USD (26 %), lecture de cache 1,01 USD (13 %), input 0,001 USD.
- Haiku : output 0,23 USD (44 %), lecture de cache 0,15 USD (29 %), écriture de cache 0,14 USD (27 %), input négligeable.

Les recalculs (Opus 7,2888 ; Haiku 0,5241) concordent avec le `cout.json`. Le poste dominant reste la sortie d'Opus.

## 3. Évolution depuis le tour 1 (19,4 min, 6,32 USD)

| | Tour 1 | Tour 2 | Écart |
|---|---|---|---|
| Coût cumulé | 6,32 USD | 7,81 USD | +1,49 USD (+23,6 %) |
| Durée | 19,4 min | 54,7 min | +35,3 min |
| Requêtes Opus | 89 | 103 | +14 |
| Requêtes Haiku | 1 | 218 | +217 |
| Coût Opus | 6,32 USD | 7,29 USD | +0,97 USD |
| Coût Haiku | 0,001 USD | 0,52 USD | +0,52 USD |
| Coût marginal | — | ≈ 0,042 USD/min sur l'intervalle | — |

Le coût moyen par minute baisse (0,33 → 0,14 USD/min) parce que la durée a presque triplé, mais le coût marginal du tour 2 est d'environ 0,04 USD/min. Le fait marquant est la hausse de 1 à 218 requêtes Haiku, qui n'est pas expliquée par les données disponibles (voir limites).

## 4. Limites de la mesure

- **Périmètre de l'agrégation** : `./dev cout` agrège l'usage Claude Code depuis le début de l'itération, sans filtre par session ni par agent. Les 218 requêtes Haiku peuvent provenir d'autres sessions de la machine ou de sous-agents ; la colonne `sous_agents` vaut 0 partout, ce qui ne permet pas de trancher. Attribution par rôle impossible en l'état.
- **Mesure partielle** : `fin` est `null`. Le coût final doit être relevé après clôture.
- **Tarifs à vérifier** : tarifs publics relevés le 2026-11-17 (`tools/sponsor/tarifs.json`), à confirmer avant tout usage contractuel.
- **Équivalent API, pas facturation** : sous abonnement Claude, le coût réel diffère (forfait).
- **Pas de constat livré** : le coût par critère reste indicatif tant qu'aucune observation ni recette n'a validé de critère.

## 5. Recommandation

Restreindre la mesure aux seules sessions de l'itération (ou ventiler par session/agent) avant de comparer les tours : la hausse Haiku de 1 à 218 requêtes ne peut pas être imputée à un rôle avec les données actuelles.
