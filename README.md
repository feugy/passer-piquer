# Developement

Un fichier docker-compose permet de lancer un conteneur `web` qui contient l'instance prestashop, et un conteneur `db` qui héberge la base de donnée MySQL.

L'instance MySQL utilise un volume vers le dossier hôte `D:\MySQL\data` (pour la persistance des données).
Le compte pour se connecter est `admin/password`.
Elle expose le port `3306`, la base de donnée est `prestashop` et les tables préfixée avec `ps_`.

L'instance prestashop à été configurée pour utiliser la base de données (hôte virtuel `db`), et le dossier du backoffice est `/var/www/html/backoffice`.
Le compte admin est `laetitia.simoninfeugas@gmail.com/poulette`.

Démarrer le site:

> cd passer-piquer

> docker-compose up

Puis ouvrir avec un navigateur [le site](http://localhost:8080) ou le [backoffice](http://localhost:8080/backoffice)

Ouvrir un shell sur un des conteneurs:

> docker exec -it passerpiquer_web_1 /bin/bash

Dossiers appartenant au user www-data

> html/modules
> html/override
> html/themes

Dossier d'images

> html/img

Paramètres:

> rm html/app/config/parameters.php
> html/app/config/parameters.yml
```
parameters:
  database_host: db
  database_port: ~
  database_name: passer_piquer
  database_user: pp_user
  database_password: password
  database_prefix: ps_
  database_engine: InnoDB
  mailer_transport: smtp
  mailer_host: 127.0.0.1
  mailer_user: ~
  mailer_password: ~
  ps_caching: CacheMemcache
  ps_cache_enable: false
  ps_creation_date: 2016-12-21
  locale: fr-FR
```
