# Autoresearch — idées futures

## Idées déposées (non poursuivies immédiatement)

- **Parallélisation des tests** : run `test-compose.sh` et `test-dockerfile.sh` en parallèle avec
  des plages de ports non-chevauchantes pour réduire le temps total (actuellement ~130s pour 9 configs).

- **CONTAINER_NAME override test** : valider que `run-dockerfile.sh` accepte un `CONTAINER_NAME`
  personnalisé sans crash (test Docker dry-run avec `--rm` + `--name`).

- **test-all.sh** : script agrégateur lançant test-compose + test-dockerfile en une commande,
  utile pour CI. Accepterait les mêmes env vars que les deux scripts.

- **GitHub API mock** : remplacer l'appel `version.remote.sh` dans les tests par un mock local
  pour éliminer complètement la dépendance au rate-limit GitHub et rendre les tests 100% offline.

- **`IDENA_API_HOST_PORT` connectivity check** : après `wait_for_health`, vérifier que le port API
  est accessible (actuellement seul SSH est testé dans `test-compose.sh`).

- **Image size optimization** : mesurer la taille de l'image Docker et explorer des pistes de
  réduction (multi-stage build, suppression de `apt-utils`).

- **Dockerfile HEALTHCHECK upgradeable** : le healthcheck du Dockerfile ne teste que le port 22.
  Aligner sur docker-compose.yml qui teste aussi le port 9009.
