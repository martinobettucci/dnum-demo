# sponsor — 2026-11-17T14:29:48+00:00

## Brief
Itération 002, fin d'itération. Lance ./dev cout et mets à jour iterations/002/cout.md : coût final de l'itération (cumulé, ventilation par modèle, évolution depuis le tour 2, coût par critère constaté livré si calculable, limites de la mesure).

## Compte rendu
Le coût de l'itération 002 est de **12,69 USD** (équivalent API) à 14:29 UTC, après 170,7 min. Ce n'est pas un coût définitif : `fin` est encore `null` dans `cout.json`, donc l'itération n'est pas clôturée. `iterations/002/cout.md` est réécrit avec ce cumul.

- **Ventilation** : Opus 7,29 USD (57 %, 103 requêtes), Haiku 5,40 USD (43 %, 2 192 requêtes). Les lectures de cache Haiku pèsent 3,94 USD.
- **Boucles AOPR** : 3 restitutions d'`observation.md` (tours 2, 3 et 3 bis), soit 11 sections `##`. `policies/results.json` montre 31 policies respectées, 0 violée.
- **Coût par critère** : 22 critères [C] recettés OK, soit environ 0,58 USD par critère (0,45 USD sur les 28 critères [C] décomptés). Deux réserves et un KO partiel ne sont pas comptés. Les corrections du tour 3 n'ont pas été recettées (pile `dev` gelée).
- **Comparaison** : par rapport au relevé précédent de l'itération (54,7 min, 7,81 USD), le coût a augmenté de 4,87 USD, soit environ 0,042 USD par minute. L'itération 001 (0,43 USD en 1,9 min) n'est pas comparable.

**Anomalie à vérifier** : le coût Opus est identique à 4 décimales (7,2888 USD, 103 requêtes) entre le relevé précédent et celui-ci, alors que la session a continué pendant 116 minutes. Soit l'agrégation Opus ne voit plus certaines sessions, soit le relevé précédent était déjà recalculé. Je ne peux pas trancher avec les données disponibles.

**Recommandation** : relancer `./dev cout` après clôture (`fin` renseigné) et vérifier pourquoi le coût Opus ne bouge pas entre deux relevés. Tant que ce n'est pas fait, le total n'est ni définitif ni attribuable à un rôle.
