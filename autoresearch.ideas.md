# Autoresearch Ideas

## Idées épuisées / écartées

- **Strip des .so glibc** : aucun gain — Debian strip déjà au maximum (`strip --strip-unneeded` = 0 byte)
- **Supprimer libm.so.6** : impossible — binary crash sans elle (libm.so.6: cannot open shared object file)
- **Remplacer jq par awk/grep** : −0.8 MB mais trop fragile — structure JSON imbriquée (`uploader: {}`) rend le parsing sans jq non fiable
- **Supprimer apk-tools** : seulement 292 KB — pas rentable, risque de casser des packages Alpine
- **UPX --ultra-brute** : même taille que -9 (30 MB) mais >3 min de build. -7 (17s) est le sweet spot
- **UPX sur les .so glibc** : impossible — les .so doivent rester des ELF valides pour le dynamic linker
- **glibc via sgerrand/alpine-pkg-glibc** : symboles incomplets (`__fprintf_chk`, `gnu_get_libc_version`, `__res_init` manquants)
- **Alpine + gcompat** : musl symbols insuffisants pour ce binaire glibc
- **Alpine + frolvlad/alpine-glibc** : segfault (libgcc_s musl incompatible avec glibc)

## Minimum théorique atteint

Image = Alpine base (8.4 MB) + glibc .so (3.2 MB) + dropbear+jq+ca-certs (2.1 MB) + binaire UPX-7 (30 MB) + tools (21 KB) = **~44 MB**

Pour aller plus loin il faudrait : compiler idena-node statiquement (non disponible) ou patcher l'ELF interpreter du binaire pour utiliser musl.
