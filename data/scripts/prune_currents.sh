# This refetches the seeder counts for everthing in torrents.csv, and updates the seeder counts
echo "Refetching seeder counts from torrents older than 3 months ..."
cd ..
# torrents_removed="`pwd`/torrents_removed.csv"
torrents_csv="`pwd`/torrents.csv"
prune_currents_tmps="`pwd`/prune_currents_tmps"
rm -rf "$prune_currents_tmps"

# Fetch updated trackerslist
trackers=$(wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt | sed  '/^$/d' | tr '\n' ,| rev | cut -c2- | rev)

mkdir $prune_currents_tmps
cd $prune_currents_tmps

cp $torrents_csv tmp

# Extract the header
header=$(head -n1 tmp)
sed -i '1d' tmp

# Get the ones older than 3 months
awk -F';' -v date="$(date -d '3 months ago' '+%s')" '$8 < date' tmp | cut -d ';' -f1 > tmp2

mv tmp2 tmp

# Split these up into 50 file batches
split -l 50 tmp tmp_

> no_seeds
for f in tmp_*; do
  echo "Fetching seeds..."
  echo $f
  torrent-tracker-health --trackers="$trackers" --torrent "$f" > health.out


  # The only reliable things here are scraped_date, hash, seeders, leechers, completed
  results=$(jq -r '.results[] | select (.created != null ) | [.hash, .seeders, .leechers, .completed, (now | floor)] | join(";")' health.out)
  # If there are no results
  if [ -z "$results" ]; then
    echo "There were no results for some reason."
    cat health.out
  else
    # Loop over the result lines
    while read -r result; do
      hash=$(echo "$result" | cut -d ';' -f1)

      # Get the first columns
      found_line=$(grep "$hash" $torrents_csv | cut -d';' -f-4)

      # Remove the hash column from my fetched results
      hash_removed=$(echo "$result" | cut -d';' -f2-)

      # Append the seeder data to the line
      new_line="$found_line"\;"$hash_removed"

      # Update the torrents.csv and infohashes scanned file
      echo "Torrents.csv updated"
      echo "$new_line"
      echo -e "$new_line" >> $torrents_csv

    done <<< "$results"


  fi
  rm $f
done

rm health.out
cd ..
rm -rf $prune_currents_tmps
cd scripts
./prune.sh
