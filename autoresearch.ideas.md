# Autoresearch Ideas

## Idées épuisées / écartées

- **Strip des .so glibc** : aucun gain — Debian strip déjà au maximum (`strip --strip-unneeded` = 0 byte)
- **Supprimer libm.so.6** : impossible — binary crash sans elle (libm.so.6: cannot open shared object file)
- **Remplacer jq par awk/grep** : ✅ FAIT — parsing via browser_download_url qui contient le nom de l'asset (−0.9 MB)
- **Supprimer apk-tools** : seulement 292 KB — pas rentable, risque de casser des packages Alpine
- **UPX --ultra-brute** : même taille que -9 (30 MB) mais >3 min de build. -7 (17s) est le sweet spot
- **UPX sur les .so glibc** : impossible — les .so doivent rester des ELF valides pour le dynamic linker
- **glibc via sgerrand/alpine-pkg-glibc** : symboles incomplets (`__fprintf_chk`, `gnu_get_libc_version`, `__res_init` manquants)
- **Alpine + gcompat** : musl symbols insuffisants pour ce binaire glibc
- **Alpine + frolvlad/alpine-glibc** : segfault (libgcc_s musl incompatible avec glibc)
- **Supprimer ca-certificates** : sécurité — nécessaire pour vérification SSL wget (GitHub HTTPS)
- **dropbear plus léger** : 4 packages minimum (dropbear + ca-certs + skalibs + utmps-libs) = 1.2 MB, impossible à réduire davantage

## Minimum théorique atteint

Image = Alpine base (8.4 MB) + glibc .so (3.2 MB) + dropbear+ca-certs (1.2 MB) + binaire UPX-7 (~31 MB) + tools (21 KB) = **~44 MB**

Pour aller plus loin il faudrait : compiler idena-node statiquement (non disponible) ou patcher l'ELF interpreter du binaire pour utiliser musl.

## Résumé des optimisations appliquées (179.1 MB → 42.0 MB, −76.5%)

1. debian:bookworm-slim + no apt-upgrade (-4.9 MB)
2. openssh-server → dropbear (-8.3 MB)
3. curl → wget (-4.0 MB)
4. **Alpine runtime + glibc copié depuis Debian** (-62.6 MB) ← plus grand gain
5. shadow → adduser busybox (-2.2 MB)
6. **UPX -7 sur binaire strippé** (82→30 MB, −44 MB) ← 2ème plus grand gain
7. GNU wget → busybox wget (-3.2 MB)
8. bash → sh POSIX (-2.0 MB)
9. jq → grep/cut/sed sur browser_download_url (-0.9 MB)
