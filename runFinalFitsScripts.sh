#!/bin/bash


#bash variables
FILE="";
EXT="auto"; #extensiom for all folders and files created by this script
PROCS="ggh"
CATS="UntaggedTag_0,UntaggedTag_1,UntaggedTag_2,UntaggedTag_3,UntaggedTag_4,VBFTag_0,VBFTag_1,VBFTag_2,TTHHadronicTag,TTHLeptonicTag,VHHadronicTag,VHTightTag,VHLooseTag,VHEtTag"
#CATS="UntaggedTag_0,UntaggedTag_1,UntaggedTag_2,UntaggedTag_3,UntaggedTag_4,VBFTag_0,VBFTag_1,VBFTag_2,TTHLeptonicTag,VHHadronicTag,VHTightTag,VHLooseTag"
#CATS="UntaggedTag_0,UntaggedTag_1,UntaggedTag_2,UntaggedTag_3,UntaggedTag_4,VBFTag_0,VBFTag_1,VBFTag_2,VHHadronicTag,VHTightTag,VHLooseTag"
SCALES="HighR9EE,LowR9EE,HighR9EB,LowR9EB"
SMEARS="HighR9EE,LowR9EE,HighR9EBRho,LowR9EBRho,HighR9EBPhi,LowR9EBPhi"
PSEUDODATADAT=""
SIGFILE=""
SIGONLY=1
BKGONLY=1
DATACARDONLY=1
COMBINEONLY=1
COMBINEPLOTSONLY=0
SUPERLOOP=1

usage(){
	echo "The script runs background scripts:"
		echo "options:"
echo "-h|--help)" 
echo "-i|--inputFile) "
echo "-p|--procs) (default $PROCS)"
echo "-f|--flashggCats) (default $CATS) "
echo "--ext) (default $EXT)"
echo "--pseudoDataDat)"
echo "--combine) "
echo "--combineOnly) "
echo "--combinePlotsOnly) "
echo "--superloop) Used to loop over the whole process N times (default $SUPERLOOP)"
echo "--signalOnly)"
echo "--backgroundOnly) "
echo "--datacardOnly)"
}


#------------------------------ parsing


# options may be followed by one colon to indicate they have a required argument
if ! options=$(getopt -u -o hi:p:f: -l help,inputFile:,procs:,flashggCats:,ext:,,pseudoDataDat:,sigFile:,combine,combineOnly,combinePlotsOnly,signalOnly,backgroundOnly,datacardOnly,superloop: -- "$@")
then
# something went wrong, getopt will put out an error message for us
exit 1
fi
set -- $options

while [ $# -gt 0 ]
do
case $1 in
-h|--help) usage; exit 0;;
-i|--inputFile) FILE=$2; shift ;;
-p|--procs) PROCS=$2; shift ;;
-f|--flashggCats) CATS=$2; shift ;;
--ext) EXT=$2; echo "test" ; shift ;;
--pseudoDataDat) PSEUDODATADAT=$2; shift;;
--signalOnly) COMBINEONLY=0;BKGONLY=0;SIGONLY=1;DATACARDONLY=0; shift;;
--backgroundOnly) COMBINEONLY=0;BKGONLY=1;SIGONLY=0;DATACARDONLY=0; shift;;
--datacardOnly) COMBINEONLY=0;BKGONLY=0;SIGONLY=0;DATACARDONLY=1; shift;;
--combine) COMBINEONLY=1;;#;BKGONLY=0;SIGONLY=0;DATACARDONLY=0;;
--combineOnly) COMBINEONLY=1;BKGONLY=0;SIGONLY=0;DATACARDONLY=0;;
--combinePlotsOnly) COMBINEPLOTSONLY=1;COMBINEONLY=1;BKGONLY=0;SIGONLY=0;DATACARDONLY=0;;
--superloop) SUPERLOOP=$2 ; shift;;

(--) shift; break;;
(-*) usage; echo "$0: error - unrecognized option $1" 1>&2; usage >> /dev/stderr; exit 1;;
(*) break;;
esac
shift
done


OUTDIR="outdir_$EXT"
echo "[INFO] outdir is $OUTDIR" 
#if [ "$FILE" == "" ];then
#	echo "ERROR, input file (--inputFile or -i) is mandatory!"
#	exit 0
#fi

#mkdir -p $OUTDIR

#if [ $FTESTONLY == 0 -a $PSEUDODATAONLY == 0 -a $BKGPLOTSONLY == 0 ]; then
#IF not particular script specified, run all!
#FTESTONLY=1
#PSEUDODATAONLY=1
#BKGPLOTSONLY=1
#fi

####################################################
##################### SIGNAL #######################
####################################################

if [ $SIGONLY == 1 ]; then

echo "------------------------------------------------"
echo "------------>> Running SIGNAL"
echo "------------------------------------------------"

cd Signal
./runSignalScripts.sh -i $FILE -p $PROCS -f $CATS --ext $EXT
cd -
fi

##Signal script only need to be run once, outside of superloop
COUNTER=0
while [ $COUNTER -lt $SUPERLOOP ]; do
echo "[INFO] on loop number $COUNTER"


####################################################
################## BACKGROUND  ###################
####################################################
if [ $BKGONLY == 1 ]; then

echo "------------------------------------------------"
echo "-------------> Running BACKGROUND"
echo "------------------------------------------------"

cd Background
./runBackgroundScripts.sh -p $PROCS -f $CATS --ext $EXT --pseudoDataDat $PSEUDODATADAT --sigFile ../Signal/$OUTDIR/CMS-HGG_sigfit_$EXT.root --seed $COUNTER 
cd -
fi

####################################################
################### DATCACARD  #####################
####################################################

if [ $DATACARDONLY == 1 ]; then

echo "------------------------------------------------"
echo "------------> Create DATACARD"
echo "------------------------------------------------"

cd Datacard
./makeParametricModelDatacardFLASHgg.py -i ../Signal/$OUTDIR/CMS-HGG_sigfit_$EXT.root  -o Datacard_13TeV_$EXT.txt -p $PROCS -c $CATS --photonCatScales $SCALES --photonCatSmears $SMEARS --isMultiPdf
cd -
fi

####################################################
##################### COMBINE  #####################
####################################################

if [ $COMBINEONLY == 1 ]; then

echo "------------------------------------------------"
echo "------------> Create COMBINE"
echo "------------------------------------------------"

cd Plots/FinalResults
cp ../../Signal/$OUTDIR/CMS-HGG_sigfit_$EXT.root CMS-HGG_mva_13TeV_sigfit.root
cp ../../Background/CMS-HGG_multipdf_$EXT.root CMS-HGG_mva_13TeV_multipdf.root
cp ../../Datacard/Datacard_13TeV_$EXT.txt CMS-HGG_mva_13TeV_datacard.txt

cp combineHarvesterOptions13TeV_Template.dat combineHarvesterOptions13TeV_$EXT.dat
sed -i "s/!EXT!/$EXT/g" combineHarvesterOptions13TeV_$EXT.dat 

cp combinePlotsOptions_Template.dat combinePlotsOptions_$EXT.dat
sed -i "s/!EXT!/$EXT/g" combinePlotsOptions_$EXT.dat

if [ $COMBINEPLOTSONLY == 0 ]; then
./combineHarvester.py -d combineHarvesterOptions13TeV_$EXT.dat -q 1nh

JOBS=999
RUN=999
PEND=999
FAIL=999
DONE=999

while [ $JOBS != 0 ];do
#bjobs
sleep 10
JOBS=`bjobs | grep $USER | wc -l`
RUN=`bjobs | grep RUN | wc -l`
PEND=`bjobs | grep PEND | wc -l`
FAIL=`ls -R  combineJobs13TeV_$EXT |grep fail |wc -l`

echo "[INFO] Processing $JOBS jobs: PEND $PEND, RUN $RUN, FAIL $FAIL"
done

echo "[INFO] ------> All jobs done"
fi
./combineHarvester.py --hadd combineJobs13TeV_$EXT

LEDGER=" --it $COUNTER --itLedger itLedger_$EXT.txt"

#./makeCombinePlots.py -f combineJobs13TeV_pilottest090915/Asymptotic/Asymptotic.root --limit -b
#./makeCombinePlots.py -f combineJobs13TeV_pilottest090915/ExpProfileLikelihood/ExpProfileLikelihood.root --pval -b
./makeCombinePlots.py -d combinePlotsOptions_$EXT.dat -b $LEDGER 
./makeCombinePlots.py -f combineJobs13TeV_$EXT/MuScan/MuScan.root --mu -t "#sqrt{s}\=13TeV L\=19.6fb^{-1}" -o mu -b $LEDGER #for some reason doesn't work in datfile

python superloopPlots.py itLedger_$EXT.txt -b 

mkdir -p $OUTDIR/combinePlots
cp *pdf $OUTDIR/combinePlots/.
cp *png $OUTDIR/combinePlots/.
rm *pdf
rm *png

if [ $USER == "lcorpe" ]; then
cp -r $OUTDIR ~/www/.
cp ~lcorpe/public/index.php ~/www/$OUTDIR/combinePlots/.
fi

cd -

fi

echo "signal output at Signal/$OUTDIR"
echo "background output at Signal/$OUTDIR"
echo "comibe output at Signal/$OUTDIR"
echo "plots available at: "
echo "https://lcorpe.web.cern.ch/lcorpe/$OUTDIR"

COUNTER=$[COUNTER + 1]
done

mv *Ledger* $OUTDIR/combinePlots/.
