#!/bin/bash
# Script that uses our metafile to select only those data and metadata files we
# need and delete the rest.

if [[ ! -e $1 || ! -e $2 ]]
then
        echo "Usage: $0 metadata_file data_directory"
        exit 1
fi
METAFILE=$1
DATADIR=$2

mkdir $DATADIR/temp
for x in `awk '{print $1}' $METAFILE` ; do mv $DATADIR/$x* $DATADIR/temp; done

rm $DATADIR/*
mv $DATADIR/temp/* $DATADIR
rmdir $DATADIR/temp
