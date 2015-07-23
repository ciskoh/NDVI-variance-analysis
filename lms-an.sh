#!/bin/bash

#path to variables
varpath=/media/matt/MJR-gis/3-Spain/ls_analysis/new/scriptvar.sh

###MAIN Script to evaluate NDVI change in one area throughout the year

#steps: 1-importing the images(script ndvi.sh) 2-athmospheric correction(script ndvi.sh) 3-NDVI(script ndvi.sh) 4-NDVI analysis against landscape patches (ls-cat.sh) 5-Export NDVI images

echo "##############################################################"

echo "Script to evaluate NDVI change in one area throughout the year 

####################################################################"


echo "steps: 
1-importing the images(script ndvi.sh) 
2-athmospheric correction(script ndvi.sh) 

3-NDVI(script ndvi.sh) 

4-creation of landscape map (ls-cat.sh)

4-NDVI analysis against landscape patches  

5-Export NDVI images"


r.mask -r

#detecting folder where script is running "sdir"

sdir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

#manual input for basic variable or script
echo "do you want to input the variables manually or to use a file?

For manual input enter 1                                       for path to variables enter 0" 
read input

if [[ "$input" -eq "1" ]]; then

	echo "define output folder (must be different from input folder)

	"
	read foldout 
	d=$(date) #for variable file
	echo "#!/bin/bash" >$foldout/scriptvar.sh  #for variable file
	echo "#Environmental variables for script lms-an.sh as manually selected on the $d" >>$foldout/scriptvar.sh  #for variable file
	
	echo "foldout=$foldout #main output folder" >>$foldout/scriptvar.sh  >>$foldout/scriptvar.sh  #for variable file
	##image import question "$imp" is the answer

	echo "Should i really import the images? 
	NO type 0			YES type 1

"
	read imp
echo "imp=$imp #importing images 1=yes" >>$foldout/scriptvar.sh  #for variable file
	if [ "$imp" -eq "1" ]

		then
		echo "define folder containing satellite images (there cannot be more then one image per month)"
		read fold
		echo "fold=$fold #folder for satellite images" >>$foldout/scriptvar.sh  #for variable file
	fi 



#question for landscape vector bulding or importing. Answer is shc

	echo "do you need to build the landscape map?

	NO type 0                  Yes type 1

"

	read shc
	echo "shc=$shc #building landscape map 1=yes" >>$foldout/scriptvar.sh  #for variable file

	if [ "$shc" -eq "0" ]; then
		echo "define path to shapefile with landscape classes"
		read lshp
		echo "lshp=$lshp #path to shapefile for landscape" >>$foldout/scriptvar.sh  #for variable file
		echo "define name of landscape codes attribute"
		read lcodes;
		echo "lcodes=$lcodes #column name with landscape codes" >>$foldout/scriptvar.sh  #for variable file
		else

			echo "

			#####################################################################

			algorithm for creation of homogeneous landscape categories based on dtm and land use map

			####################################################################"
			#Specify layers and variables

			#TODO: add label management for subdivisions

			##########ask for input landuse and dtm

			# ask DTM
			echo "specify the DTM complete path with extension

			"
			read DTM
			echo "DTM=$DTM #path to DTM" >>$foldout/scriptvar.sh  #for variable file
			#ask Land use
			echo " specify the land use vector path with extension

			"
			read LU
			echo "LU=$LU #path to land use vector" >>$foldout/scriptvar.sh  #for variable file

			#ask if subdivisions. if yes ask for column with subdivisions 
			echo "does $LU have subdivisions for different managements or land use types?

			If YES type 1           if No type 0"
			read sub
			
			echo "sub=$sub #option for land use types subdivision 1=yes" >>$foldout/scriptvar.sh  #for variable file
			if [ "$sub" -eq "1" ]
				then
				echo "specify column with number categories for land use subdivision"
				read col
				echo "col=$col #column with number of categories" >>$foldout/scriptvar.sh  #for variable file
			fi

			echo "specify path to slope rules"
			read srul
			echo "srul=$srul #path to slope rules" >>$foldout/scriptvar.sh  #for variable file
			echo "specify path to asp rules"
			read arul
			echo "arul=$arul #path to asp rules" >>$foldout/scriptvar.sh  #for variable file

			echo "DTM is $DTM"
			echo " land use is $LU"
			#####END: ask of input
	fi
	echo "what type of quantile calculation do you want? 

0 for yearly					1 for monthly"
read ycalc 
echo "ycalc=$ycalc #type of quantile calculation 0=yearly" >>$foldout/scriptvar.sh
echo "file with variable created: check $foldout/scriptvar.sh"
#read ok


else

	. $varpath
fi

#writing file with script details
readme=$foldout/README-script-details.txt #path to readme txt
echo "Evaluation of NDVI change in one area throughout the year" >$readme
loc=$(g.gisenv -n get=LOCATION_NAME)
da=$(date)
echo "Executed for the area of $loc on $da">>$readme 

sets=$(sed -n 3,13p $varpath)
echo "
Using the following settings:
$sets">>$readme

echo "check readme file at $readme"
#read ok

echo "$foldout , $fold $code $LU, $arul"
##read ok
#create output folder
#TODO optimize folder creation
mkdir -p $foldout/ndvi
mkdir -p $foldout/statistics
mkdir -p $foldout/vectors
mkdir -p $foldout/rasters


g.region res=30

#landscape vector map creation or importing

if [ "$shc" -eq "1" ]; then

	. $sdir/ls-cat.sh;
	else

	#IMPORTING landscape
	v.in.ogr dsn=$lshp output=landscape min_area=0.0001 snap=1 cname="cat,value"
	g.region vect=landscape

	v.to.rast input=landscape output=landscape use=attr column=$lcodes
fi



r.mask input=landscape


#obtain list of category values
r.stats -n input=landscape >$foldout/statistics/landscape_values.txt
lsv=`cat $foldout/statistics/landscape_values.txt`; 


####END of Importing and correcting landscape


################LANDSAT import, athmospheric correction and ndvi calculation on subscript ndvi.sh




if [ "$imp" -eq "1" ];
	then
	echo "I will import the images"
	##read ok
	. $sdir/ndvi.sh;
	else 
	nlist2=`cat $foldout/statistics/ndvi_list2.txt`
	echo "I will not import the images, will use those  instead $nlist2"
	##read ok;
fi

########classification of ndvi variance through variance.sh

# for state map
s=a0
basemap=landscape_state
mkdir -p $foldout/state
foldout2=$foldout/state

	. $sdir/variance.sh


echo "continue with management???"
##read ok
basemap=landscape
s=a1
mkdir -p $foldout/management
foldout2=$foldout/management


	. $sdir/variance.sh

###END of classification
g.mremove -f rast=*norm*,temp*
r.mask -r

echo "ALL finished
#
##
###
####
#####
######
#######


GOODBYE GOODBYE GOODBYE GOODBYE GOODBYE


#######
######
####
###
##
#
"



