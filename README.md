# Torrents.csv

<!-- Torrents.csv - An open source, collaborative repository of torrents, with a self-hostable web server.   -->

[Demo Server](https://torrents-csv.ml)

`Torrents.csv` is a *collaborative* repository of torrents and their files, consisting of a searchable `torrents.csv`, and `torrent_files.csv`. With it you can search for torrents, or files within torrents. It aims to be a universal file system for popular data.

Its initially populated with a January 2017 backup of the pirate bay, and new torrents are periodically added from various torrents sites. It comes with a self-hostable [Torrents.csv webserver](https://torrents-csv.ml), a command line search, and a folder scanner to add torrents, and their files.

`Torrents.csv` will only store torrents with at least one seeder to keep the file small, will be periodically purged of non-seeded torrents, and sorted by infohash.

![img](https://i.imgur.com/yTFuwpv.png)

To request more torrents, or add your own, go [here](https://gitea.com/heretic/torrents-csv-data).

Made with [Rust](https://www.rust-lang.org), [ripgrep](https://github.com/BurntSushi/ripgrep), [Actix](https://actix.rs/), [Inferno](https://www.infernojs.org), [Typescript](https://www.typescriptlang.org/).

## Webserver

`Torrents.csv` comes with a simple webserver. [Demo Server](https://torrents-csv.ml)

### Docker

```
docker run -d --rm -p 8902:8902 justsky/torrents-csv:latest
```

And goto http://localhost:8902

### Docker Development

```
git clone --recurse-submodules https://codeberg.org/heretic/torrents-csv-server
cd torrents-csv-server/docker/dev
./docker_update.sh
```

## Command Line Searching

### Requirements

- [ripgrep](https://github.com/BurntSushi/ripgrep)

### Running

```
git clone --recurse-submodules https://codeberg.org/heretic/torrents-csv-server
cd torrents-csv-server
./search.sh "bleh season 1"
bleh season 1 (1993-)
	seeders: 33
	size: 13GiB
	link: magnet:?xt=urn:btih:INFO_HASH_HERE
```

## API

A JSON output of search results is available at:

`http://localhost:8902/service/search?q=[QUERY]&size=[NUMBER_OF_RESULTS]&page=[PAGE]&type=[torrent | file]`

New torrents are at:

`http://localhost:8902/service/new?size=[NUMBER_OF_RESULTS]&page=[PAGE]&type=[torrent | file]`

