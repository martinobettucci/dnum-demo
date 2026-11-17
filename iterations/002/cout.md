# Itération 002 — Coût final (sponsor, clôture)

Source : `./dev cout` en deux relevés, à la clôture (`fin` = 2026-11-17T16:12:37 UTC).
- Relevé (1) : `./dev cout` sans filtre → `iterations/002/cout-agents.json`
- Relevé (2) : `DEVENV_COST_PROJECT=-home-spark-docker ./dev cout` → `iterations/002/cout-sessions.json`

Tarifs : `tools/sponsor/tarifs.json` (relevés le 2026-11-17, à vérifier). Montants en USD, équivalent API.

## 1. Synthèse

| Indicateur | Valeur |
|---|---|
| **Total = (1) + (2)** | **34,7578 USD** (équivalent API) |
| Sous-total relevé (1), agents | 14,0719 USD |
| Sous-total relevé (2), sessions | 20,6859 USD |
| Durée | 273,4 min (4 h 33), de 11:39:13 à 16:12:37 UTC |
| Requêtes (1) / (2) | 2 985 / 449 (total 3 434) |
| Boucles AOPR observées | **5** restitutions dans `observation.md` : tour 2, tour 3, tour 3 bis, incident recette, clôture |

**Avertissement :** la somme (1) + (2) n'est pas un total fiable (voir § 5). Les deux relevés se chevauchent probablement et ne sont pas cohérents entre eux.

## 2. Ventilation par relevé

### Relevé (1) — sans filtre, 14,0719 USD

| Modèle | Requêtes | Input | Output | Cache écriture | Cache lecture | Coût USD |
|---|---|---|---|---|---|---|
| claude-haiku-5-5 | 2 882 | 5 764 | 2 079 243 | 6 291 433 | 495 647 793 | 6,7831 |
| claude-opus-5-5 | 103 | 206 | 212 543 | 405 457 | 5 049 029 | 7,2888 |

Aucune ligne Sonnet dans ce relevé.

### Relevé (2) — filtré projet `-home-spark-docker`, 20,6859 USD

| Modèle | Requêtes | Input | Output | Cache écriture | Cache lecture | Coût USD |
|---|---|---|---|---|---|---|
| claude-haiku-5-5 | 82 | 212 | 55 119 | 352 490 | 14 118 322 | 0,2128 |
| claude-opus-5-5 | 169 | 462 | 126 754 | 225 051 | 55 587 214 | 14,7796 |
| claude-sonnet-5-5 | 198 | 552 | 138 818 | 301 542 | 35 503 208 | 5,6935 |

### Ventilation cumulée par modèle (somme brute des deux relevés)

| Modèle | Requêtes | Coût USD | Part du total brut |
|---|---|---|---|
| claude-opus-5-5 | 272 | 22,0684 | 63,5 % |
| claude-haiku-5-5 | 2 964 | 6,9959 | 20,1 % |
| claude-sonnet-5-5 | 198 | 5,6935 | 16,4 % |
| **Total** | **3 434** | **34,7578** | 100 % |

Contrôle : 14,0719 + 20,6859 = 34,7578 USD. Requêtes : 2 985 + 449 = 3 434.

## 3. Évolution

| Mesure | Coût USD | Durée | Remarque |
|---|---|---|---|
| Itération 001 (relevé précoce, Opus seul) | 0,43 | 1,9 min | Instantané très précoce, non comparable |
| Itération 002, tour 2 | 7,81 | 54,7 min | Relevé de `cout.md` précédent |
| Itération 002, relevé du 14:29 | 12,69 | 170,7 min | Relevé intermédiaire |
| Itération 002, relevé (1) à la clôture | 14,07 | 273,4 min | Sans filtre |
| Itération 002, total final (1) + (2) | 34,76 | 273,4 min | Voir avertissement § 5 |

- Par rapport au tour 2 (7,81 USD) : +26,95 USD, soit un coût multiplié par 4,45.
- Par rapport à l'itération 001 (0,43 USD) : la comparaison n'est pas significative, car le relevé 001 n'a pas été relancé après 1,9 min.
- Le relevé (1) n'a progressé que de 1,38 USD depuis 14:29 (Haiku 5,40 → 6,78 ; Opus inchangé à 7,2888). Le relevé (2) n'est pas comparable avec les précédents, car il est filtré.

## 4. Coût par critère

- Critères [C] OK recettés au tour 2 : 22 (rapport `cout.md` intermédiaire). Dénominateur : 28 critères [C] décomptés.
- Coût par critère OK : 34,76 / 22 ≈ **1,58 USD** (indicatif).
- Coût par critère [C] visé : 34,76 / 28 ≈ **1,24 USD** (indicatif).
- Le compte final des critères constatés livrés n'a pas été refait à la clôture. La passe 3 de recette est verte avec réserves (`cloture.md`), mais la liste finale OK/KO n'est pas recomptée ici. Ces ratios sont donc à considérer comme indicatifs.

## 5. Limites de la mesure

1. **Relevés incohérents entre eux.** Le relevé (1), sans filtre, contient 103 requêtes Opus et aucune requête Sonnet. Le relevé (2), filtré sur le projet, contient 169 requêtes Opus et 198 requêtes Sonnet. Un relevé sans filtre devrait être au moins égal à un relevé filtré. Le total Opus de (1) (7,2888 USD) est aussi identique, à 4 décimales, à la valeur du relevé 14:29 et à celle du tour 2. C'est l'anomalie déjà signalée dans le relevé 14:29. Elle n'est pas résolue.
2. **Chevauchement probable.** Les deux relevés couvrent la même période (11:39:13 → 16:12:37) et peuvent compter les mêmes requêtes. La somme (1) + (2) peut donc double-compter. Le total de 34,76 USD est une borne haute, et non un coût mesuré.
3. **Périmètre non filtré par agent.** La colonne `sous_agents` vaut 0 partout. L'attribution par rôle (developpeur, testeur, client, sponsor, etc.) n'est pas possible avec cet outil. Une partie des requêtes peut venir d'autres sessions de la machine. Le relevé (2) filtre sur le projet, pas sur l'itération.
4. **Tarifs à vérifier.** Les tarifs de `tools/sponsor/tarifs.json` sont relevés le 2026-11-17 et ne sont pas vérifiés contre la grille officielle. Pas d'usage contractuel sans vérification.
5. **Équivalent API, pas facturation.** Sous abonnement Claude, le coût réel diffère (forfait). Les 34,76 USD sont une valorisation, non une dépense.
6. **Critères.** Le ratio par critère repose sur un décompte intermédiaire (22 OK au tour 2), pas sur le décompte final.

## 6. Recommandation

Corriger `./dev cout` pour que le relevé sans filtre soit toujours supérieur ou égal au relevé filtré, puis relancer les deux relevés. Tant que ce n'est pas fait, le total de 34,76 USD ne doit servir qu'à une borne haute, pas à une comparaison entre itérations.
