# sponsor — 2026-11-17T16:12:44+00:00

## Brief
Itération 002 CLÔTURÉE (iterations/002/.ended renseigné) : coût FINAL, en 2 relevés. (1) Lance ./dev cout, puis copie iterations/002/cout.json en iterations/002/cout-agents.json. (2) Lance DEVENV_COST_PROJECT=-home-spark-docker ./dev cout, puis copie cout.json en iterations/002/cout-sessions.json. Total = (1) + (2). Mets à jour iterations/002/cout.md : total final en USD (équivalent API), ventilation par relevé et par modèle, durée, évolution depuis le tour 2 (7,81 USD) et l'itération 001 (0,43 USD), coût par critère constaté livré si calculable, et les limites de la mesure : le relevé (2) peut contenir des sessions sans lien avec l'itération sur la période, les tarifs sont des relevés publics à vérifier, sous abonnement le coût réel diffère. Donne le total et les deux sous-totaux dans ta réponse. Aucun secret ni e-mail.

## Compte rendu
**Coût final de l'itération 002 : 34,76 USD (équivalent API), soit 14,07 USD + 20,69 USD.** C'est la somme brute des deux relevés, et elle ne doit pas être prise pour un total fiable (voir ci-dessous).

- **Relevé (1), `./dev cout` sans filtre : 14,0719 USD** (`cout-agents.json`) : Haiku 6,7831 (2 882 requêtes), Opus 7,2888 (103 requêtes).
- **Relevé (2), filtre projet `-home-spark-docker` : 20,6859 USD** (`cout-sessions.json`) : Haiku 0,2128 (82), Opus 14,7796 (169), Sonnet 5,6935 (198).
- **Durée :** 273,4 min, de 11:39 à 16:12 UTC.
- **Boucles AOPR :** 5 restitutions dans `observation.md` (tour 2, tour 3, tour 3 bis, incident recette, clôture).
- **Évolution :** +26,95 USD par rapport au tour 2 (7,81 USD, ×4,45). La comparaison avec l'itération 001 (0,43 USD) n'est pas significative.
- **Coût par critère :** environ 1,58 USD par critère [C] OK (22 critères, décompte du tour 2) et 1,24 USD par critère [C] visé (28). Ces ratios sont indicatifs.

Le total est fragile. Le relevé (1), sans filtre, a moins de requêtes Opus (103) que le relevé (2) filtré (169), et aucune requête Sonnet. Le total Opus du relevé (1) est aussi identique à celui du relevé de 14:29. Les deux relevés couvrent la même période et se chevauchent probablement, donc 34,76 USD est une borne haute.

Recommandation : corriger `./dev cout` pour que le relevé sans filtre soit toujours au moins égal au relevé filtré, puis relancer les deux relevés avant toute comparaison entre itérations.

Le rapport est dans `iterations/002/cout.md`. Il ne contient ni secret ni e-mail.
