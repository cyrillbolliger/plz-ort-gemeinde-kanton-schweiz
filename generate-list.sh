#!/bin/bash

#
# Create a list that maps ZIP codes to location names and their political municipality and canton in Switzerland.
#
# The script uses the data of the [Swiss Federal Register of Buildings and Dwellings](https://www.bfs.admin.ch/bfs/en/home/registers/federal-register-buildings-dwellings.html). As location names sometimes belong to multiple municipalities, the script maps them to the municipality where the most buildings belong to. This may result in a small number of erronerous mappings.


set -euo pipefail

# get the latest data from then BFS
wget https://data.geo.admin.ch/ch.bfs.gebaeude_wohnungs_register/CSV/CH/CH.zip

# unpack it and convert it into a true CSV
unzip -p CH.zip CH.csv | awk '{for (i=1;i<=NF;i++) $i="\""$i"\""}1' FS=";" OFS="," > data.csv

# put it into an sqlite database
sqlite3 -csv db.sqlite ".import data.csv data"

# and export PLZ, Ort, Gemeinde and Kanton into plz-ort-gemeinde-kanton-schweiz.csv
sqlite3 -header -csv db.sqlite "SELECT PLZ, Ort, Gemeinde, Kanton FROM (SELECT PLZ, Ort, Gemeinde, Kanton, MAX(c) AS m FROM (SELECT DPLZ4 AS PLZ, DPLZNAME AS Ort, GDENAME AS Gemeinde, GDEKT AS Kanton, COUNT(DPLZNAME) AS c FROM data GROUP BY Ort, Gemeinde) GROUP BY Ort) ORDER BY PLZ, Ort;" > plz-ort-gemeinde-kanton-schweiz.csv

# remove temporary data
rm CH.zip data.csv db.sqlite
