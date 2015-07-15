#!/bin/bash

#script that calculates classes of variance through multiple ndvi images using yearly quantiles and minimum value is 2% quantile
#input: surface re4flectance derived ndvi images, 
#Variance 2 calculates quantiles over the all year instead of monthly

#obtain list of category values
lsv=$(r.stats -n input=$basemap)
echo "this is lsv: $lsv"
#####read ok

#starting cycle for each category

echo "

***************************************************
starting cyle for quantiles calculations and co.


*****************************************************" 
r.mask -r
scount=0

for g in $lsv ;
do

	echo "calculating quantiles for category $g"
	
	#creating mask for category $g
	echo "creating mask for category $g"
	r.mask -o input=$basemap maskcats=$g
	####read ok
	nlist=$(g.mlist type=rast pattern=corr*)
	nlist2=$(g.mlist type=rast pattern=corr* separator=comma)
	#creating output folder
	mkdir -p $foldout2/statistics
	mkdir -p $foldout2/rasters
	#TODO change potential calculation from yearly mean to single frame 
	#calculation of year round 90th quantile
	if [[ scount -eq "0" ]]; then #if for creating folder for statistics
			mkdir -p $foldout2/statistics/category_stats
			mkdir -p $foldout2/statistics/category_stats/$g
		fi
	#calculation of statistics
	r.univar -e map=$nlist2 percentile=25,50,75,90,2 >$foldout2/statistics/category_stats/$g-yearly-stats.txt

	echo "check $foldout2/statistics/category_stats/$g-yearly-stats.txt"
	###read ok
	#identifying 90th quantile
	mpath=$foldout2/statistics/category_stats/$g-yearly-stats.txt #path to yearly stats
	p90a=$(sed -n '22p' < $mpath)

	p90=${p90a#*:}

	yquant=$(echo "$p90*1000" | bc -l)
	
	#lower 2 % quantiles
	p2a=$(sed -n '23p' < $mpath)
	p2=${p2a#*:}
	lquant=$(echo "$p2*1000" | bc -l)
	echo "yquant is $yquant nad lquant is $lquant"
	##read ok
#cycle through images
#counter
	count=0
	for h in $nlist; do 
		#extracting filename of NDVI images	
		ndname=${h%@*}
		
		echo "counter is $count"
		echo "

	working on image $h for category $g

	"
#####read ok
		######read ok
		
	#actual calculation of percentiles
		if [[ count -eq "0" ]]; then
			mkdir -p $foldout2/statistics/category_stats
			#mkdir -p $foldout2/statistics/category_stats/$g
		fi
		#string for statistics file 
		spath=$foldout2/statistics/category_stats/$g/$g-$ndname-stats.txt
	
		r.univar -e map=$h percentile=25,50,75,90 >$spath

	
		p90a=$(sed -n '22p' < $spath)

		p90=${p90a#*:}

		quant=$(echo "$p90*1000" | bc -l)


		

		echo "check stats in $foldout2/statistics/rec_rules/rec_rules_$g"-"$ndname.txt"
		######read ok
		
		#exporting quantile values in other text file for $g

		#filename for value list for each landscape class
			vlist=$foldout2/statistics/category_stats/lsvalue.csv
		#first time file creation
		dcount=$((count+scount))
		if [[ dcount -eq "0" ]]; then
			echo "creating text file with quantile values for $g"
			#creating column headers
			echo "landscape; date; NDVI-90; MIN; MEDIAN; VARCOEFF" >$vlist
		fi
		#extraction of 9oth quantile, Min, Median, Variation coefficient, for present category
		#NDVI90
		NDVI90=$(sed -n '22p' < $spath)
		NDVI90=${NDVI90#*:}
		
		#Min
		min=$(sed -n '7p' < $spath)
		min=${min#*:}

		#Median
		med=$(sed -n '17p' < $spath)
		med=${med#*:}

		#Variation coefficient
		varc=$(sed -n '14p' < $spath)
		varc=${varc#*:}
		
		#writing values on the vlist file
		echo "writing values on the vlist file"
		echo "$g; $ndname; $NDVI90; $min; $med; $varc" >>$vlist
		echo "$g; $ndname; $NDVI90; $min; $med; $varc"		
		#####read ok

		echo "check statistics @ $vlist"
		######read ok

		##normalised ndvi maps using all year step quantiles

		#reducing highest values at 90th quantile
		str1=$s"temp"
		r.mapcalc "$str1=if(MASK,float($h*1000.00),null())"
		str25=$s"temp25"
		r.mapcalc "$str25=float(if($str1>$yquant,$yquant,$str1))"
		echo "check $str2 max value should be $yquant"
		#eliminating noise through 2% quantiles
		#str2=$s"temp2"
		#r.mapcalc "$str2=float(if($str25<$lquant,$lquant,$str25))"
		#echo "check $str2 max value should be $yquant and lowest value should be $lquant"
		###read ok
###read ok
 
		
		
		#TODO: verify if better reclass or rescale (to prevent loosing variance)
		#actual reclassification
		#TODO problem with masks
		str3=$s"_"$ndname"_norm_"$g

		#r.reclass input=$str2 output=$str3 rules=$foldout2/statistics/rec_rules/rec_rules_$g"-"$ndname.txt
		
		#rescale instead of rclassify
		r.rescale input=$str25 output=$str3 to=0,100
		echo "rescale instead of reclassify 
		

	check $str3"
		#creating folder for exporting str3
		if [[ count=0 ]]; then
		mkdir -p /$foldout2/rasters/$h
		fi
		#exporting str3
		r.out.gdal input=$str3 output=/$foldout2/rasters/$h/$str3".tiff" nodata=255
		
		count=$((count+1))
		echo "
		
		cycle finished for category $g and image $h
		
		";
		###read ok

	done
	r.mask -r
	#creating a group for all timesteps for each category
	#list of all images for present landscape class
	#atime=$(g.mlist -m pattern=$s"_*_norm_"$g* separator=comma)

	#group images for $g
	#i.group group=$s"_"$g"_group" input=$atime
	#exporting all imagesfor present landscape category to multilayer tiff
	#r.out.gdal input=$s"_"$g"_group" output=$foldout2/rasters/$g"-multiband.tiff"
	
	echo "#######################################################

	CYLE finished for all images on category $g

	##############################################################"
	###read ok 
	scount=$((scount+1))
	r.mask -r;

done


echo "check mask"

r.mask -o input=$basemap
###read ok
##Merging all the images of one timestep together using gdal
dir $foldout2/rasters/*/
###read ok
for i in $foldout2/rasters/*/; do
	cd $i
	nd=$(basename $i)
	list=$(dir $i)
	echo "nd is $nd and list is $list"
	###read ok
	gdal_merge.py -n 255 -of GTiff -o -a_nodata 255 $foldout2/rasters/final_$nd".tiff" $list
	echo "merged"
	###read ok
	#reimporting all final images per each month
	r.in.gdal --overwrite input=$foldout2/rasters/final_$nd".tiff" output=$s"_final_"$nd;
done

echo "prepare for final map"
###read ok
fl=$(g.mlist type=rast pattern=$s"_final*" separator=comma)
echo "fl is $fl"
#creation of mode and stddev map
r.series input=$fl output=$s"_final_allyear",$s"_final_stdev",$s"_final_linreg" method=average,stddev,slope
echo "check "$s"_final_allyear",$s"_final_stdev",$s"_final_linreg before exporting"
###read ok

#exporting final maps
r.out.gdal input=$s"_final_allyear" output=/$foldout/rasters/$s"_final_allyear.tiff" nodata=255
r.out.gdal input=$s"_final_stdev" output=/$foldout/rasters/$s"_final_stdev.tiff"     nodata=255
r.out.gdal input=$s"_final_linreg" output=/$foldout/rasters/$s"_final_linreg.tiff"   nodata=255




echo "
############
##############
#################

VARIANCE.SH IS FINISHED!!!!
GOING BACK TO LMS-AN.SH

#################
###############
############
"


