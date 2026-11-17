# Policies (écrites par l'agent `policy`)
Contraintes de vérification exécutables, lancées par `./dev policies` dans le conteneur `runner`.
Résultats : `iterations/NNN/policies/results.json`, lus par l'agent `observation`.
En-tête obligatoire : `# POLICY:`, `# REF:`, `# QUAND: always|deployed`. Code retour 0 / 1 / 77.
