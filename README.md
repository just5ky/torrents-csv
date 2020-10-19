# Torrents.csv

<!-- Torrents.csv - An open source, collaborative repository of torrents, with a self-hostable web server.   -->

[Demo Server](https://torrents-csv.ml)

`Torrents.csv` is a *collaborative* repository of torrents and their files, consisting of a searchable `torrents.csv`, and `torrent_files.csv`. With it you can search for torrents, or files within torrents. It aims to be a universal file system for popular data.

Its initially populated with a January 2017 backup of the pirate bay, and new torrents are periodically added from various torrents sites. It comes with a self-hostable [Torrents.csv webserver](https://torrents-csv.ml), a command line search, and a folder scanner to add torrents, and their files.

`Torrents.csv` will only store torrents with at least one seeder to keep the file small, will be periodically purged of non-seeded torrents, and sorted by infohash.

![img](https://i.imgur.com/yTFuwpv.png)

To request more torrents, or add your own, go [here](https://gitlab.com/dessalines/torrents.csv/issues).

Made with [Rust](https://www.rust-lang.org), [ripgrep](https://github.com/BurntSushi/ripgrep), [Actix](https://actix.rs/), [Inferno](https://www.infernojs.org), [Typescript](https://www.typescriptlang.org/).

## Webserver

`Torrents.csv` comes with a simple webserver. [Demo Server](https://torrents-csv.ml)

### Docker

```
git clone https://gitlab.com/dessalines/torrents.csv
cd torrents.csv
cd scripts && ./build_sqlite.sh -f && cd ..
cd docker/prod
docker-compose up -d
```
### Docker Development

```
git clone https://gitlab.com/dessalines/torrents.csv
cd torrents.csv/scripts && ./build_sqlite.sh && cd ..
cd docker/dev
docker-compose up -d
```

### Local

#### Requirements

- [Rust](https://www.rust-lang.org/)
- [Yarn](https://yarnpkg.com/en/)
- [SQLite3](https://www.sqlite.org/index.html)

#### Running

```
git clone https://gitlab.com/dessalines/torrents.csv
cd torrents.csv/scripts
./webserver.sh
```
and goto http://localhost:8902

If running on a different host, run `export TORRENTS_CSV_ENDPOINT=http://whatever.com` to change the hostname, or use a reverse proxy with nginx or apache2.

The torrent data is updated daily, and to do so, run, or place this in a crontab:

`cd scripts && ./git_update.sh`

This updates the repository, and rebuilds the sqlite cache necessary for searching.

To re-build the frontend assets, use `cd server/ui && yarn build`. There is no need to restart the `./webserver.sh` script.

## Command Line Searching

### Requirements

- [ripgrep](https://github.com/BurntSushi/ripgrep)

### Running
```
git clone https://gitlab.com/dessalines/torrents.csv
cd torrents.csv
./search.sh "bleh season 1"
bleh season 1 (1993-)
	seeders: 33
	size: 13GiB
	link: magnet:?xt=urn:btih:INFO_HASH_HERE
```
## Uploading / Adding Torrents from a Directory

An *upload*, consists of making a pull request after running the `scan_torrents.sh` script, which adds torrents from a directory you choose to the `.csv` file, after checking that they aren't already there, and that they have seeders. It also adds their files to `torrent_files.csv`.

### Requirements
- [Torrent-Tracker-Health Dessalines branch](https://github.com/dessalines/torrent-tracker-health)
  - `npm i -g dessalines/torrent-tracker-health`
- [jq command line JSON parser: Needs at least jq-1.6](https://stedolan.github.io/jq/)
- [NodeJS](https://nodejs.org/en/)
- [Gnu Parallel](https://www.gnu.org/software/parallel/)

### Running
[Click here](https://gitlab.com/dessalines/torrents.csv/forks/new) to fork this repo.
```sh
git clone https://gitlab.com/[MY_USER]/torrents.csv
cd torrents.csv/scripts
./scan_torrents.sh MY_TORRENTS_DIR # `MY_TORRENTS_DIR` is `~/.local/share/data/qBittorrent/BT_backup/` for qBittorrent on linux, but you can search for where your torrents are stored for your client.
git commit -am "Adding [MY_USER] torrents"
git push
```

Then [click here](https://gitlab.com/dessalines/torrents.csv/merge_requests/new) to do a pull/merge request to my branch.

## Web scraping torrents
`Torrents.csv` has a `Rust` repository for scraping new and top torrents from some torrent sites in the `new_torrents_fetcher` folder. It currently scrapes skytorrents, magnetdl, and leetx.

### Requirements
- Rust
- [Cloudflare Scrape](https://github.com/Anorov/cloudflare-scrape)
  - `sudo pip install cfscrape`

### Running
```
git clone https://gitlab.com/dessalines/torrents.csv
cd torrents.csv/scripts
./update.sh SAVE_TORRENT_DIR
```

## API
A JSON output of search results is available at:

http://localhost:8902/service/search?q=[QUERY]&size=[NUMBER_OF_RESULTS]&offset=[PAGE]&type=[torrent | file]

new torrents are at:

http://localhost:8902/service/new?size=[NUMBER_OF_RESULTS]&offset=[PAGE]&type=[torrent | file]

## How the torrents.csv file looks
```sh
infohash;name;size_bytes;created_unix;seeders;leechers;completed;scraped_date
# torrents here...
```

## How the torrent_files.csv looks
```sh
infohash;index;path;size_bytes
```
