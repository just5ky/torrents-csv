#!/bin/bash
csv_file="./data/torrents.csv"
torrent_files_csv="../torrent_files.csv"
db_file="${TORRENTS_CSV_DB_FILE:-./torrents.db}"
build_files=false

while getopts ":f" opt; do
  case $opt in
    f)
      build_files=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

echo "Creating temporary torrents.db file..."

# Remove double quotes for csv import
sed 's/\"//g' $csv_file > torrents_removed_quotes.csv

# Sort by seeders desc before insert
sort --field-separator=';' --key=5 -nr -o torrents_removed_quotes.csv torrents_removed_quotes.csv

touch db_tmp

sqlite3 -batch db_tmp <<"EOF"
drop table if exists torrents;
create table torrents(
  "infohash" TEXT,
  "name" TEXT,
  "size_bytes" INTEGER,
  "created_unix" INTEGER,
  "seeders" INTEGER,
  "leechers" INTEGER,
  "completed" INTEGER,
  "scraped_date" INTEGER
);
.separator ";"
.import torrents_removed_quotes.csv torrents
UPDATE torrents SET completed=NULL WHERE completed = '';
EOF
rm torrents_removed_quotes.csv

if $build_files ; then
  # Cache torrent files
  echo "Building files DB from $torrent_files_csv ..."

  # Remove double quotes for csv import
  sed 's/\"//g' $torrent_files_csv > torrent_files_removed_quotes.csv

  # Removing those with too many ;
  awk -F \; 'NF == 4' <torrent_files_removed_quotes.csv > torrent_files_temp_2

  rm torrent_files_removed_quotes.csv
  mv torrent_files_temp_2 torrent_files_temp

sqlite3 -batch db_tmp<<EOF
create table files_tmp(
"infohash" TEXT,
"index_" INTEGER,
"path" TEXT,
"size_bytes" INTEGER
);
.separator ";"
.import torrent_files_temp files_tmp

-- Filling the extra columns
create table files(
"infohash" TEXT,
"index_" INTEGER,
"path" TEXT,
"size_bytes" INTEGER,
"created_unix" INTEGER,
"seeders" INTEGER,
"leechers" INTEGER,
"completed" INTEGER,
"scraped_date" INTEGER
);
insert into files
select files_tmp.infohash,
files_tmp.index_,
files_tmp.path,
files_tmp.size_bytes,
torrents.created_unix,
torrents.seeders,
torrents.leechers,
torrents.completed,
torrents.scraped_date
from files_tmp
inner join torrents on files_tmp.infohash = torrents.infohash
order by torrents.seeders desc, files_tmp.size_bytes desc;
delete from files where seeders is null;
drop table files_tmp;
EOF
rm torrent_files_temp
fi

mv db_tmp $db_file
echo "Done."
