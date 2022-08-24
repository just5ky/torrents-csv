#!/bin/bash

# This prunes torrents.csv, removing those with too many columns, and sorts it
echo "Pruning torrents.csv ..."
pushd ..
torrents_csv="`pwd`/torrents.csv"
torrents_csv_tmp="`pwd`/torrents_prune_tmp.csv"
scanned_out="`pwd`/infohashes_scanned.txt"

# torrent_files_csv="`pwd`/torrent_files.csv"
# torrent_files_csv_tmp="`pwd`/torrent_files_tmp.csv"

cp $torrents_csv $torrents_csv_tmp

# Remove lines that don't have exactly 7 ';'
rg "^([^;]*;){7}[^;]+$" $torrents_csv_tmp > tmp_adds
mv tmp_adds $torrents_csv_tmp

# Remove random newlines
sed -i '/^$/d' $torrents_csv_tmp

# Extract the header
header=$(head -n1 $torrents_csv_tmp)
sed -i '1d' $torrents_csv_tmp

# Sort by seeders desc (so when we remove dups it removes the lower seeder counts)

# Remove dups, keeping the last ones
tac $torrents_csv_tmp | sort -u -t';' -k1,1 -o $torrents_csv_tmp

# Same for the infohashes scanned
sort -u -o $scanned_out $scanned_out

# Remove torrents with zero seeders
awk -F';' '$5>=1' $torrents_csv_tmp> tmp
mv tmp $torrents_csv_tmp

# Sort by infohash asc
sort --field-separator=';' --key=1 -o $torrents_csv_tmp $torrents_csv_tmp

# Add the header back in
sed  -i "1i $header" $torrents_csv_tmp
#truncate -s -1 $torrents_csv # Removing last newline

# Remove heinous shit
grep -ivwE "(1yo|2yo|3yo|4yo|5yo|6yo|7yo|8yo|9yo|10yo|11yo|12yo|13yo|14yo|15yo|16yo|XXX|busty|teenfidelity|deepthroat|faketaxi|brazzers|brazzersexxtra|brazzerslive|porn|anal|pussy|pussies|creampies?|creampied|tits|cocks?|pov|fucking|femdom|rapes?|cum|cumming|cunnilingus|familystrokes|iknowthatgirl)" $torrents_csv_tmp > tmp
mv tmp $torrents_csv_tmp

mv $torrents_csv_tmp $torrents_csv

# Torrent files cleanup
# echo "Pruning torrent_files.csv ..."
# cp $torrent_files_csv $torrent_files_csv_tmp

# Header
# header=$(head -n1 $torrent_files_csv_tmp)
# sed -i '1d' $torrent_files_csv_tmp

# Remove dups, keeping the last ones
# tac $torrent_files_csv_tmp | sort -u -t';' -k1,1 -k2,2 -o $torrent_files_csv_tmp

# Same for the infohashes scanned
# sort --field-separator=';' --key=1,2 -o $torrent_files_csv_tmp $torrent_files_csv_tmp

# Add the header back in
# sed  -i "1i $header" $torrent_files_csv_tmp

# mv $torrent_files_csv_tmp $torrent_files_csv

popd

echo "Pruning done."
