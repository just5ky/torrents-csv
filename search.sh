#!/bin/bash
torrent_csv_file="`pwd`/data/torrents.csv"

search_string=${1// /.*} # turn multiple string regexes into i.*am.*spartacus

# Read the lines of the results
rg -i "$search_string" $torrent_csv_file | sort --field-separator=';' --key=5 -g | while read -r line; do
  infohash=$(echo -e "$line" | cut -d ';' -f1)
  magnet_link="magnet:?xt=urn:btih:$infohash"
  name=$(echo -e "$line" | cut -d ';' -f2)
  seeders=$(echo -e "$line" | cut -d ';' -f5)
  size_bytes=$(echo -e "$line" | cut -d ';' -f3)
  size=$(numfmt --to=iec-i --suffix=B $size_bytes)
  # Construct the search result
  result="$name\n\tseeders: $seeders\n\tsize: $size\n\tlink: $magnet_link"
  echo -e "$result"
done

