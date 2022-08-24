#!/bin/bash

# Checking arguments
# Help line

torrents_csv="`pwd`/../torrents.csv"
scanned_out="`pwd`/../infohashes_scanned.txt"
tmp_torrent_dir="`pwd`/../tmp_torrents-$RANDOM"

# Fetch updated trackerslist
trackers=$(wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt | sed  '/^$/d' | tr '\n' ,| rev | cut -c2- | rev)

touch $scanned_out

help="Run ./scan_torrents.sh [TORRENTS_DIR] \nor goto https://gitlab.com/dessalines/torrents.csv for more help"
if [ "$1" == "-h" ] || [ -z "$1" ]; then
  echo -e $help
  exit 1
fi

torrents_dir="$1"
echo "Torrents dir=$torrents_dir"

# Check dependencies

if command -v "torrent-tracker-health" >/dev/null 2>&1 ; then
  echo "torrent-tracker-health installed."
else
  echo -e "Installing torrent-tracker-health:\nnpm i -g dess-torrent-tracker-health \nhttps://codeberg.org/heretic/torrent-tracker-health\n"
  npm i -g install dess-torrent-tracker-health
fi

# Loop over all torrents
pushd $torrents_dir
# Copy the unscanned torrent files to a temp dir
mkdir $tmp_torrent_dir
# TODO need to find a better way to do this for huge dirs

# Diff the dirs
find $torrents_dir -type f -name "*.torrent" -printf "%f\n" | rev | cut -f 2- -d '.' | rev > scanning_tors

# A set difference
sort scanning_tors $scanned_out $scanned_out | uniq -u > to_be_scanned

# Build the file names again
sed "s|^|$torrents_dir/|; s|$|.torrent|" to_be_scanned > to_be_scanned_files

# Copy them over
rsync -a / --no-relative --files-from=to_be_scanned_files $tmp_torrent_dir

rm to_be_scanned_files
rm to_be_scanned
rm scanning_tors

# Split these into many directories ( since torrent-tracker-health can't do too many full size torrents)
cd $tmp_torrent_dir
# i=1;while read l;do mkdir $i;mv $l $((i++));done< <(ls|xargs -n100)
ls|parallel -n50 mkdir {#}\;mv {} {#}

for tmp_torrent_dir_sub in *; do
  echo "sub dir:$tmp_torrent_dir/$tmp_torrent_dir_sub"
  find $tmp_torrent_dir_sub -type f  -exec basename {} .torrent \; > names.out

  # Delete null torrents from the temp dir
  find $tmp_torrent_dir_sub -name "*.torrent" -size -2k -delete

  if [ -z "$(ls -A $tmp_torrent_dir_sub)" ]; then
    echo "No new torrents."
  else
    # Scrape it
    torrent-tracker-health --trackers="$trackers" --torrent "$tmp_torrent_dir_sub"/ > health.out

    # Convert the json results to csv format
    # Created is sometimes null, and a weird date
    results=$(jq -r '.results[] | select (.created != null ) | [.hash, .name, .length, (.created | .[0:16] | strptime("%Y-%m-%dT%H:%M") | mktime), .seeders, .leechers, .completed, (now | floor)] | join(";")' health.out)
    # If there are no results
    if [ -z "$results" ]; then
      echo "There were no results for some reason."
      cat health.out
    else
      echo "Torrents.csv updated with new torrents."
      echo "$results"

      # Update the torrents.csv and infohashes scanned file
      echo -e "$results" >> $torrents_csv
      cat names.out >> $scanned_out
    fi
  fi
done

popd

# Remove the temp dir
rm -rf "$tmp_torrent_dir"

# Scan the torrent dir for new files, and add them
# node --max-old-space-size=8096 scan_torrent_files.js --dir "$torrents_dir"

./prune.sh
