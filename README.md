# Idena Node Docker Image

[![Docker Hub](https://img.shields.io/docker/pulls/rinzlerfr/idena-node)](https://hub.docker.com/repository/docker/rinzlerfr/idena-node)
[![Docker Image Size](https://img.shields.io/docker/image-size/rinzlerfr/idena-node/latest)](https://hub.docker.com/repository/docker/rinzlerfr/idena-node)
[![Docker Automated build](https://img.shields.io/docker/automated/rinzlerfr/idena-node)](https://hub.docker.com/repository/docker/rinzlerfr/idena-node)
[![GitHub Stars](https://img.shields.io/github/stars/Rinzler78/docker.idena-node?style=social)](https://github.com/Rinzler78/docker.idena-node/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/Rinzler78/docker.idena-node?style=social)](https://github.com/Rinzler78/docker.idena-node/network/members)
[![GitHub issues](https://img.shields.io/github/issues/Rinzler78/docker.idena-node)](https://github.com/Rinzler78/docker.idena-node/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/Rinzler78/docker.idena-node)](https://github.com/Rinzler78/docker.idena-node/commits/master)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/Rinzler78/docker.idena-node/issues)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Overview

This repository provides a ready-to-use Docker image to run an Idena node easily and securely, with SSH access and persistent data storage.
Utiliser un nœud Idena vous permet de participer activement au réseau Idena, de valider des transactions et de contribuer à la décentralisation. Exécuter votre nœud via Docker simplifie l'installation, la gestion des dépendances et assure un environnement isolé et reproductible.
For more information about the Idena project, visit [idena.io](https://idena.io/).

---

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Update Instructions](#update-instructions)
- [Synology NAS Deployment](#synology-nas-deployment)
- [Security Considerations](#security-considerations)
- [FAQ / Troubleshooting](#faq--troubleshooting)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Simple deployment of an Idena node via Docker
- SSH access to the container
- Automatic update of the Idena node binary
- Persistent data storage via Docker volumes
- Easy migration from existing nodes
- Public image available on Docker Hub

---

## Architecture

```mermaid
graph TD;
  User["User (SSH client)"] -->|SSH| SSHPort["Host:{SshPort}"]
  SSHPort -->|Port interne 22 du conteneur| Container["idena-node container"]
  Container -->|API:9009 (accessible via tunnel SSH)| SSHPort
  Container -->|P2P:40405| Network["P2P Network"]
  Container -->|/datadir| Volume["Host Data Directory"]
```

---

## Prerequisites

- Docker (version 20+ recommended)
- Supported OS: Linux, macOS, Windows (with Docker)
- At least 2GB RAM and 2GB free disk space
- Internet connection

---

## Quick Start

First, create a directory on your host to persist node data and, if you have one, copy your `api.key` into it:
```sh
mkdir -p ~/MyDockers/idena-node/datadir
# Si vous avez une clé API existante :
# cp /path/to/your/api.key ~/MyDockers/idena-node/datadir/api.key
```

Then, run the container:
```sh
docker run -d \
  --restart unless-stopped \
  -p 60022:22 \
  -p 40405:40405 \
  -p 9999:9999 \
  -v ~/MyDockers/idena-node/datadir:/datadir \
  -e IDENA_USER_ACCOUNT_NAME=idenaUser \
  -e IDENA_USER_ACCOUNT_PASS=idenaUserPassword \
  --name idena-node rinzlerfr/idena-node
```
Explications des options :
- `-d`: Exécute le conteneur en arrière-plan (detached mode).
- `--restart unless-stopped`: Redémarre automatiquement le conteneur sauf s'il a été explicitement arrêté (par exemple, par `docker stop idena-node`).

> **Note:**
> Le mappage du port SSH (`-p 60022:22`) est requis si vous souhaitez vous connecter à votre nœud via SSH, par exemple pour utiliser la redirection de port avec la commande :
> ```sh
> ssh -L 9999:localhost:9009 idenaUser@<host_ip> -p 60022
> ```
> Ici, `60022` est juste un exemple : vous pouvez le remplacer par n'importe quel port libre de votre choix, tant que vous utilisez le même numéro de port dans les commandes `docker run` et `ssh`. Ceci est nécessaire pour permettre à l'application de bureau Idena de se connecter à votre nœud distant comme s'il était local (l'application se connectera à `http://localhost:9999`).
>
> Le mappage `-p 9999:9999` dans la commande `docker run` expose le port API du nœud. Si le service API à l'intérieur du conteneur écoute sur le port `9009` (standard Idena), et que vous souhaitez y accéder directement via `http://<host_ip>:9999` (sans tunnel SSH), vous devriez plutôt utiliser `-p 9999:9009`. Si l'accès se fait *exclusivement* via le tunnel SSH (comme décrit ci-dessus), ce mappage de port direct `-p 9999:9999` (ou `-p 9999:9009`) n'est pas strictement nécessaire pour cette méthode d'accès spécifique, car le tunnel gère la connexion au port `9009` interne du conteneur. Le diagramme d'architecture illustre l'accès API via le port interne `9009` du conteneur, typiquement atteint par le tunnel SSH.

**Replace:**
- `60022` with your desired SSH port
- `~/MyDockers/idena-node/datadir` with your data directory path
- `idenaUser` and `idenaUserPassword` with your SSH credentials

---

## Configuration

| Variable                   | Description                        | Required | Example           |
|----------------------------|------------------------------------|----------|-------------------|
| IDENA_USER_ACCOUNT_NAME    | SSH user account name              | Yes      | idenaUser         |
| IDENA_USER_ACCOUNT_PASS    | SSH user account password          | Yes      | idenaUserPassword |

**Data directory:**
Create a directory on your host to persist node data (if not already done in Quick Start) and copy your `api.key` into it:

```sh
mkdir -p ~/MyDockers/idena-node/datadir
cp /path/to/your/api.key ~/MyDockers/idena-node/datadir/api.key
```
Votre `api.key` est généralement trouvée dans le répertoire `datadir` de votre installation Idena existante, ou est générée par le client Idena lors de la première configuration d'un nœud local. Si vous n'en avez pas, le nœud en générera une lors du premier démarrage, mais vous devrez la récupérer depuis le conteneur (par exemple, via SSH) pour l'utiliser avec l'application de bureau.

---

## Usage

### Build the image (optional)

If you want to build the image locally:

```sh
docker build -t idena-node .
```

### Run the container

See [Quick Start](#quick-start).

### Connect to the node from Idena Desktop App

To access your remote node API securely from your local Idena desktop app, use SSH port forwarding:

```sh
ssh -L 9999:localhost:9009 idenaUser@<host_ip> -p 60022
```
(Si l'application Idena Desktop s'exécute sur la même machine que le conteneur Docker, vous pouvez utiliser `localhost` comme `<host_ip>`.)

Then, in the Idena app, set the node address to:
`http://localhost:9999`

---

## Update Instructions

1. Pull the latest image:
   ```sh
   docker pull rinzlerfr/idena-node
   ```
2. Stop and remove the existing container (data is preserved):
   ```sh
   docker stop idena-node
   docker rm idena-node
   ```
3. Run the container again with your previous command. (Assurez-vous d'utiliser exactement les mêmes paramètres `-p`, `-v`, et `-e` que lors du lancement initial pour conserver votre configuration et vos données.)

---

## Synology NAS Deployment

1. **Install Docker** via the Package Center.
2. **Search for `rinzlerfr/idena-node`** in the Docker registry and download it.
3. **Create the data directory** (e.g., `docker/idena-node/datadir`).
4. **Copy your `api.key`** into the data directory.
5. **(Optional) Migrate existing node data** by copying all files from your old datadir.
6. **Configure and start the container** via the Docker GUI:
   - Set up volumes, ports, and environment variables as described above.

---

## Security Considerations
- **Mot de passe SSH :** Il est fortement recommandé d'utiliser un mot de passe SSH (`IDENA_USER_ACCOUNT_PASS`) robuste et unique.
- **Exposition du port SSH :** Considérez attentivement les implications de l'exposition du port SSH de votre conteneur à Internet. Si possible, limitez l'accès à ce port via des règles de pare-feu, en n'autorisant que des adresses IP de confiance.
- **Clé API :** Protégez votre `api.key`. Ne la partagez pas publiquement.

---

## FAQ / Troubleshooting

### Port already in use

Make sure the ports (SSH port like 60022, Idena P2P 40405, Idena API if directly exposed like 9999) are not used by another service on your host.

### Permission denied on /datadir

Ensure the Docker user has read/write permissions on the mapped directory. Vous pouvez essayer de corriger les permissions avec `sudo chown -R $(id -u):$(id -g) ~/MyDockers/idena-node/datadir` (adaptez le chemin si nécessaire et assurez-vous que l'utilisateur qui exécute cette commande est celui qui a créé le répertoire ou a les droits sudo) ou assurez-vous que l'utilisateur exécutant Docker a les droits. Sous Windows, vérifiez les paramètres de partage de lecteurs de Docker Desktop.

### Cannot SSH into the container

Check SSH port mapping, username, password, and host IP. Ensure the SSH service is running in the container (it should be by default).

### Container does not restart

Use `--restart unless-stopped` in your `docker run` command.

### How to check container logs?
Use the command `docker logs idena-node` to see the node's output.

**For other issues, open an issue on GitHub or see [Support](#support).**

---

## Support

- Open an issue on [GitHub](https://github.com/Rinzler78/docker.idena-node/issues)
- Contact: @Rinzler78 (maintainer)

If you find this project useful, donations are welcome:
`0x3fc4e0d8dcc6d767eb5381abe89f52cad874a8e5`

---

## Contributing

Contributions are welcome!
Please open an issue or a pull request on [GitHub](https://github.com/Rinzler78/docker.idena-node).

---

## License

MIT — see [LICENSE](LICENSE) for details.

---
