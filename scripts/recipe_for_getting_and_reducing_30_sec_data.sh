#!/bin/bash
# This script creates PEMs data files containing 30 second data files containing flow, occupancy, and speed 
# data.  Each file is named with the convention IIIIIII_MM_DD_YYYY.txt, where IIIIIII = station ID, MM=month,
# SS=day, and YYYY=year
#
# It uses raw data files and metadata files, both of which are downloaded from the PeMS website.
# The output of this script are a data file and an information file containing metadata for 
# each station.  This script creates data files for ALL of the stations in a Caltrans district.
# There is also a metadata file generated containing only the stations in the section of the freeway
# system selected by the "freeway" "direction" "start_absolute_postmile" and "stop_absolute_postmile"
# arguments. This file can be used with the script "select_station_data_files.sh" to keep only the 
# data files necessary.  
#
# This process was done in two steps to save processing time.  If each line in the original huge data
# file were compared with all of the selected freeway and postmile limits, it would take close to 
# forever to process the data. As it is, it takes an hour or more to write all the data files, so be happy.

if [[ ! -e $1 || ! -e $2 ]] 
then
	echo "Usage: $0 metadata_file data_file freeway direction start_absolute_postmile stop_absolute_postmile"
	exit 1
fi
METAFILE=$1
DATAFILE=$2
FREEWAY=$3
DIRECTION=$4
START_ABS_POSTMILE=$5
STOP_ABS_POSTMILE=$6

# Create a directory for the metadata and data files from the data file name, named with the convention
# ddd_DD_MM_YYYY, where ddd = Caltrans district, e.g. d10_05_13_2014
DIRNAME=`echo $DATAFILE | sed 's/[\._]/ /g' | awk '{print $1"_"$6"_"$7"_"$5}'`
mkdir $DIRNAME

if [[ `grep "gz" $DATAFILE` ]]
then
	gunzip $DATAFILE
	DATAFILE=`echo $DATAFILE | sed 's/\./ /2' | awk '{print $1}'`
fi

#The metadata file contains a description of all the stations within a Caltrans 
#district. It is created periodically and contains unchanging data such as 
#station ID, postmile, lat, long, number of lanes, etc.  It is used here to 
#create a single description file for each station containing those parameters 
#we need, as well as a description of the associated data file columns.

#1. Download the metadata file for the Caltrans District from 
#PeMS Clearinghouse>Type>Station Metadata, District>District 10
#        e.g. d10_text_meta_2014_04_16.txt
#
#2. Delete the county column from this file.  This value is sometimes listed
# and sometimes not listed, so create a new metadata file without this column.
# The next column, postmile, sometimes has a decimal point and sometimes not,
# so we have to look for a number that does not have a decimal point AND has
# four or more numerals in it. 
METAFILENOCOUNTY=`echo $METAFILE | sed 's/\./ /g' | awk '{print $1}'`_no_county_col.txt

awk '{ if ( (!($6 ~/\./)) && ($6 ~/..../)) print $1,$2,$3,$4,$5,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20; else print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20}' $METAFILE >$DIRNAME"_temp_metafile1.txt"

# The same problem exists with the "Length" (whatever that is), which should now (after searching for the county column) reside
# in column 10
awk '{ if ($10 ~/[a-zA-Z]/) print $1,$2,$3,$4,$5,$6,$7,$8,$9,"0.0",$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20; else print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20}' $DIRNAME"_temp_metafile1.txt">$METAFILENOCOUNTY

if [[ $FREEWAY != "" ]]
then
	mv $METAFILENOCOUNTY $DIRNAME"_temp_metafile2.txt"
	awk -v freeway=$FREEWAY '{ if ($2 == freeway) print $0}' $DIRNAME"_temp_metafile2.txt">$METAFILENOCOUNTY
fi

if [[ $DIRECTION != "" ]]
then
	mv $METAFILENOCOUNTY $DIRNAME"_temp_metafile3.txt"
	awk -v direction=$DIRECTION '{ if ($3 == direction) print $0}' $DIRNAME"_temp_metafile3.txt">$METAFILENOCOUNTY
fi

if [[ ($START_ABS_POSTMILE != "") &&  ($STOP_ABS_POSTMILE != "") ]]
then
	mv $METAFILENOCOUNTY $DIRNAME"_temp_metafile4.txt"
	awk -v start_abs_postmile=$START_ABS_POSTMILE -v stop_abs_postmile=$STOP_ABS_POSTMILE '{ if ( ($7 > start_abs_postmile) && ($7 < stop_abs_postmile) ) print $0}' $DIRNAME"_temp_metafile4.txt">$METAFILENOCOUNTY
fi

cp $METAFILENOCOUNTY $DIRNAME

#3. Create separate metadata files in the data directory DIRNAME, named with
# the convention SSSSSSS_info.txt, where SSSSSSS = station ID
# The contents of each metadata file are:
# 1 Station ID
# 2 Freeway
# 3 Direction
# 4 State Postmile
# 5 Absolute Postmile
# 6 Latitude
# 7 Longitude
# 8 Length (of what? units?)
# 9 Type (e.g ML=Mainline)
# 10 Number of lanes
# 11 Location name (e.g. "S/O Roth Rd")
# 12 Format of data file:
# Timestamp Lane1_flow Lane1_occ Lane1_speed Lane2_flow Lane2_occ Lane2_speed Lane3_flow Lane3_occ Lane3_speed Lane4_flow Lane4_occ Lane4_speed Lane5_flow Lane5_occ Lane5_speed Lane6_flow Lane6_occ Lane6_speed Lane7_flow Lane7_occ Lane7_speed Lane8_flow Lane8_occ Lane8_speed

exec 5<$METAFILENOCOUNTY
while read line1 <&5
do
	STATION=`echo $line1 | awk '{print $1}'`
	echo $line1 | awk '{print $1"\n"$2"\n"$3"\n"$6"\n"$7"\n"$8"\n"$9"\n"$10"\n"$11"\n"$12"\n"$13,$14,$15,$16,$17,$18,$19,$20"\nTimestamp Lane1_flow Lane1_occ Lane1_speed Lane2_flow Lane2_occ Lane2_speed Lane3_flow Lane3_occ Lane3_speed Lane4_flow Lane4_occ Lane4_speed Lane5_flow Lane5_occ Lane5_speed Lane6_flow Lane6_occ Lane6_speed Lane7_flow Lane7_occ Lane7_speed Lane8_flow Lane8_occ Lane8_speed" }' >$DIRNAME/$STATION'_info.txt'
done


exec 6<$DATAFILE
while read line1 <&6
do
	NOCOMMAS=`echo $line1 | sed '{s/,$/,0/}' | sed '{s/,,/,0,/g}' | sed '{s/,,/,0,/g}' | sed '{s/,/ /g}' | cut -d ' ' -f 2-`
	STATION=`echo $NOCOMMAS | awk '{print $2}'`
	DATE=`echo $line1 | awk '{print $1}' | sed '{s/\///g}'`
	x=`echo $NOCOMMAS | awk '{print $1}'`
	y=`echo $NOCOMMAS | cut -d ' ' -f 3-`
	echo $x $y >>$DIRNAME/$STATION"_"$DATE".txt"
done
