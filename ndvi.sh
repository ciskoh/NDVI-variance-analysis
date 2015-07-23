#!/bin/bash

#Script that runs through a folder with landsat images, imports them in grass and calculates ndvi for each of them. Used as subscript of ndvi yearly analysis and modifications.

#requires the following variables: 
#fold=folder with satellite images foldout=output 
#foldout=folder with /ndvi subfolder for export

# 1-IMPORTING IMAGES
#set adequate resolution

count=0

g.region res=30
echo "here is the setting from the region:"
g.region -p

#detect name os satellite image

for i in $fold/*;
do

	 #updating the counter


	echo "


	this is the $count time I do the script.....


	"
	#identify month of picture

	echo "i is $i"
	name=${i##*/}
	echo "name is $name"
	##read ok
	ent=$(sed -n '21p' $i/$name"_MTL.txt")
	ent="$(echo "${ent}" | tr -d '[[:space:]]')"

	ldate="${ent##*=}"
	#ldate2=$(echo -e "${ldate}" | sed -e 's/^[[:space:]]*//')
	echo "ent is $ent date is =$ldate"
	year="${ldate:2:2}"
	echo "year is $year"
	#ent2=${ldate#*-}
	#echo "ent2 is $ent2"
	sdate=${ldate:5:2}
	
	echo "YEAR is $year"
	##read ok
	
		echo "ent is $ent, year is $year,ldate is $ldate sdate is $sdate yoyoyo"
	##read ok
		if [ $((10#$sdate)) -eq 01 ]; then
		month=jan
		elif [ $((10#$sdate)) -eq 02 ]; then
		month=feb
		elif [ $((10#$sdate)) -eq 03 ]; then
		month=mar
		elif [ $((10#$sdate)) -eq 04 ]; then
		month=apr
		elif [ $((10#$sdate)) -eq 05 ]; then
		month=may
		elif [ $((10#$sdate)) -eq 06 ]; then
		month=jun
		elif [ $((10#$sdate)) -eq 07 ]; then
		month=jul
		elif [ $((10#$sdate)) -eq 08 ]; then
		month=aug
		elif [ $((10#$sdate)) -eq 09 ]; then
		month=sep
		elif [ $((10#$sdate)) -eq 10 ]; then
		month=oct
		elif [ $((10#$sdate)) -eq 11 ]; then	
		month=nov
		elif [ $((10#$sdate)) -eq 12 ]; then
		month=dec
	fi

	if [[ count -eq "0" ]]; then
		
	
		echo "****************************
		
		The following images are considered for the analysis:

	
		">>$readme
	fi

	echo "name=$short date=$ldate image=$name" >>$readme
	 
	echo "month is $month; check output file $readme"
	#read ok

	short=$year$month

	#short=${name:9:7};
	#echo "short is $short";
	echo "short is $short"
	##read ok

	#subloop to import all bands of the image

	for b in $i/*; do
	
		if [[ $b =~ .*\.TIF$ ]];then
		echo "$b is a TIF"
		band=${b##*/}
	
		sband=${band:21:4}
		sband=${sband//./}

		#import bands for image 

		echo "importing band $sband"
		r.in.gdal -o --overwrite input=$b output=$short$sband;
		fi;
	done 

echo "check imported bands of image $name"
####read ok

# 2-ATHMOSPHERIC CORRECTION

#name of metadata file
meta=$i/$name"_MTL.txt"

#name of corrected picture
corr="corr_"$short"_"

#athmospheric correction

i.landsat.toar input_prefix=$short"_B" output_prefix=$corr metfile=$meta sensor=ot8 method=dos2

echo "check athmospheric corrected images"
####read ok

#3-ndvi calculation
#ndvi for corrected images

b4=$corr"4"
b5=$corr"5"

echo "this are the rasters for ndvi: $b4 and $b5"
####read ok


#NDVI calc-string for mapcalc

r.mapcalc "corr$short=float($b5-$b4)/($b5+$b4)"

echo "verify NDVI: corr$short"

#exporting NDVI

r.out.gdal -c -f input=corr$short type=Float64 output=$foldout/ndvi/corr_$short".tif"

echo "check exported ndvi at $foldout/ndvi"



#deleting useless raster
echo "cycle finished!!!!!



deleting useless raster...."

g.mremove -f rast=$short*
g.mremove -f rast=$corr*

echo "cycle restarting"
####read ok

done

#obtain list of all ndvi maps
g.mlist -m pattern='corr*' separator=comma >/$foldout/statistics/ndvi_list.txt
g.mlist -m pattern='corr*' >/$foldout/statistics/ndvi_list2.txt

echo "check list at /$foldout/statistics/ndvi_list.txt"
####read ok

#end
echo "all the images from $fold have been imported into grass

##################################################################

END OF NDVI.SH

RETURNING TO LMS-AN.SH

#################################################################"


