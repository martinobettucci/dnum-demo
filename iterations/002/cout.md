# Itération 002 — Coût (sponsor, tour 1, mesure partielle)

Source : `./dev cout` → `iterations/002/cout.json`. Mesure **en cours** : `fin` est `null`, l'itération n'est pas close. Les chiffres ci-dessous couvrent le début de l'itération jusqu'au moment de la mesure.

## 1. Synthèse

| Indicateur | Valeur |
|---|---|
| Coût total estimé (équivalent API) | **6,32 USD** (6,3248) |
| Durée écoulée | 19,4 min (début 11:39:13 UTC) |
| Requêtes | 90 (89 Opus, 1 Haiku) |
| Boucles AOPR documentées (sections de `observation.md`) | **0** — le fichier `observation.md` n'existe pas encore ; le journal ne montre qu'un passage policy/action (11:49) et des résultats de policies (11:56) |
| Coût par critère d'acceptation livré | **Non calculable** — aucun critère n'est encore constaté livré (pas d'observation, pas de recette client) |

## 2. Ventilation par modèle

| Modèle | Requêtes | Input | Output | Cache écriture | Cache lecture | Coût USD | Part |
|---|---|---|---|---|---|---|---|
| claude-opus-5-5 | 89 | 178 | 185 540 | 347 211 | 4 381 276 | 6,3238 | 99,98 % |
| claude-haiku-5-5 | 1 | 2 | 139 | 7 043 | 0 | 0,0010 | 0,02 % |

Décomposition du coût Opus (vérifiée par recalcul avec `tools/sponsor/tarifs.json`) :

- output : 3,71 USD (59 %)
- écriture de cache : 1,74 USD (27 %)
- lecture de cache : 0,88 USD (14 %)
- input : 0,001 USD (négligeable)

Le poste dominant est la **sortie** du modèle Opus, pas le contexte relu.

## 3. Comparaison avec l'itération 001

| | Itération 001 | Itération 002 (à ce jour) |
|---|---|---|
| Coût total | 0,43 USD | 6,32 USD (×14,7) |
| Durée | 1,9 min | 19,4 min (×10,2) |
| Requêtes | 9 | 90 (×10) |
| Modèles | Opus seul | Opus + 1 requête Haiku |
| Coût par minute | 0,23 USD/min | 0,33 USD/min |

L'itération 001 était un cadrage court ; la comparaison de coût n'est pas équivalente à périmètre égal. Le coût par minute augmente d'environ 44 %.

## 4. Périmètre de la boucle (pour contexte)

`perimetre.md` retient 17 user stories (US-1 à US-17), dont des critères `[C]` (client clavier/souris) et `[T]` (test automatique). Le nombre exact de critères n'a pas été recompté ici ; environ 36 lignes à puces existent dans la section 3, qui mêle conventions et critères. Le coût par critère sera chiffrable quand la recette et l'observation existeront.

## 5. Limites de la mesure

- **Mesure partielle** : `fin` est `null`. Le coût final doit être relevé après clôture de l'itération.
- **Tarifs à vérifier** : les tarifs de `tools/sponsor/tarifs.json` sont des tarifs publics relevés le 2026-11-17, à confirmer avant tout usage contractuel. Le cache d'écriture est appliqué à 1,25 × input (cache 5 min).
- **Abonnement vs API** : le montant est un **équivalent API**. Sous abonnement Claude, le coût réel facturé diffère (forfait, pas de facturation au token).
- **Sous-agents** : la colonne `sous_agents` est à 0 pour tous les modèles ; on ne peut pas exclure que l'usage des sous-agents soit rattaché ailleurs. À vérifier si la ventilation par rôle est demandée.
- **Haiku** : la requête Haiku (1 requête, 7 043 tokens de cache écrits) n'est pas attribuée à un agent précis par la mesure.

## 6. Recommandation

Relancer `./dev cout` à la clôture de l'itération (après renseignement de `fin`) et calculer le coût par critère à partir de l'observation et de la recette client, pour pouvoir comparer les itérations sur une base chiffrée.
