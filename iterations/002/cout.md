# Itération 002 — Coût (sponsor, fin d'itération)

Source : `./dev cout` → `iterations/002/cout.json`, relevé à **14:29 UTC**. Début 11:39:13 UTC. `fin` est encore `null` dans le relevé : l'itération n'est **pas clôturée** au moment de la mesure. Les chiffres ci-dessous sont donc un cumul à 14:29, pas un coût définitif.

## 1. Synthèse

| Indicateur | Valeur |
|---|---|
| Coût cumulé estimé (équivalent API) | **12,69 USD** (12,6858) |
| Durée à la mesure | 170,7 min (2 h 51) |
| Requêtes | 2 295 (103 Opus, 2 192 Haiku) |
| Boucles AOPR (restitutions d'`observation.md`) | **3** : tour 2, tour 3, tour 3 bis (final). 11 sections `##` au total |
| Policies exécutées | `policies/results.json` : 31 respectées, 0 violée, 0 non applicable (`pile_demarree: true`, 13:46) |
| Critères [C] recettés OK | **22** (sur 28 critères [C] décomptés en tour 3), plus 2 réserves (CA-002-9, CA-002-27) et 1 KO partiel (CA-002-28) |
| Coût par critère [C] OK | **≈ 0,58 USD** (12,69 / 22) ; ≈ 0,45 USD par critère [C] visé (12,69 / 28), indicatif |

## 2. Ventilation par modèle (`tools/sponsor/tarifs.json`, recalcul vérifié)

| Modèle | Requêtes | Input | Output | Cache écriture | Cache lecture | Coût USD | Part |
|---|---|---|---|---|---|---|---|
| claude-opus-5-5 | 103 | 206 | 212 543 | 405 457 | 5 049 029 | 7,2888 | 57,4 % |
| claude-haiku-5-5 | 2 192 | 4 384 | 1 689 620 | 4 898 420 | 393 949 035 | 5,3970 | 42,6 % |

Décomposition par type de jeton (recalcul : Opus 7,2888 ; Haiku 5,3970 ; total 12,6858) :

- Opus : output 4,25 USD, écriture de cache 2,03 USD, lecture de cache 1,01 USD, input 0,001 USD.
- Haiku : lecture de cache 3,94 USD, output 0,84 USD, écriture de cache 0,61 USD, input négligeable.
- Tous modèles : sortie 5,10 USD (40 %), lecture de cache 4,95 USD (39 %), écriture de cache 2,64 USD (21 %), input 0,001 USD.

## 3. Durée et cadence

- Durée : 170,7 min. Coût moyen : 0,074 USD/min.
- Entre le relevé précédent de cette itération (54,7 min, 7,81 USD) et celui-ci : +116 min, +4,87 USD, soit **≈ 0,042 USD/min** de coût marginal.

## 4. Comparaison

**Avec le relevé précédent de l'itération 002 (54,7 min, 7,81 USD) :**

| | Relevé précédent | Relevé final | Écart |
|---|---|---|---|
| Coût cumulé | 7,81 USD | 12,69 USD | +4,87 USD (+62 %) |
| Durée | 54,7 min | 170,7 min | +116 min |
| Requêtes Opus | 103 | 103 | 0 |
| Requêtes Haiku | 218 | 2 192 | +1 974 |
| Coût Opus | 7,2888 USD | 7,2888 USD | **0** (anomalie, voir § 6) |
| Coût Haiku | 0,5242 USD | 5,3970 USD | +4,87 USD |

**Avec l'itération 001 :** `iterations/001/cout.json` donne 0,43 USD (Opus, 9 requêtes) pour 1,9 min. Ce relevé est un instantané très précoce (le cumul n'a pas été relancé ensuite, `fin` null) : la comparaison de coût total n'est pas significative. L'itération 001 n'a pas de `cout.md`.

## 5. Limites de la mesure

- **Non clôturée** : `fin` est `null`. Ce chiffre est un cumul à 14:29 UTC. Un relevé définitif demande `./dev cout` après clôture.
- **Périmètre non filtré** : `./dev cout` agrège tout l'usage Claude Code depuis 11:39 UTC, sans filtre par session ni par agent. La colonne `sous_agents` vaut 0 partout : l'attribution par rôle (developpeur, testeur, client, sponsor, etc.) n'est pas possible. Les 2 192 requêtes Haiku peuvent venir d'autres sessions de la machine.
- **Tarifs à vérifier** : tarifs relevés le 2026-11-17 dans `tools/sponsor/tarifs.json`. Non vérifiés contre la grille officielle à cette date. Pas d'usage contractuel sans vérification.
- **Équivalent API, pas facturation** : sous abonnement Claude, le coût réel diffère (forfait).
- **Critères livrés partiels** : les 22 critères OK viennent de la recette du tour 2. La recette du tour 3 (corrections CA-002-27/28/34/37/38/39) n'a pas été exécutée (gel de la pile `dev`). Ces critères ne sont donc pas constatés livrés. Les critères [T] et [R] ne sont pas recettés par le client : ils ne figurent pas au dénominateur.
- **Recette à la souris et au clavier uniquement** : le compte rendu client signale une réserve sur l'étape 6 bis (URL non vérifiable) et un incident d'exécution à l'étape 13. Ces points n'invalident pas les 22 critères, mais ils fragilisent le décompte.
- **Lecture de l'observation** : les 3 restitutions sont cumulées dans `observation.md`. Je compte les boucles par restitution, pas par cycle de policy.

## 6. Anomalie de mesure à vérifier

Le coût Opus est **identique à 4 décimales** (7,2888 USD, 103 requêtes, mêmes jetons) entre le relevé précédent (54,7 min) et celui-ci (170,7 min), alors que la session a continué pendant 116 min et que Haiku a progressé de 1 974 requêtes. Soit l'agrégation Opus ne voit plus les sessions Opus après 54,7 min, soit le relevé précédent était déjà recalculé. Dans les deux cas le total Opus est suspect. À vérifier avant toute comparaison de coût par agent ou par tour.

## 7. Recommandation

Relancer `./dev cout` à la clôture (`fin` renseigné) et vérifier pourquoi le coût Opus ne bouge pas entre deux relevés. Sans cela, le chiffre de 12,69 USD n'est ni définitif ni attribuable.
