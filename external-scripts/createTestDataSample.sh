# Creates subsample of input data for RRBS
# ex: bash createTestDataSample.sh Muscle2
set -ueo pipefail

if [[ $# -eq 0 ]] ; then
    echo 'ERROR: REQUIRED ARGUMENT MISSING'
    echo 'Requires 1 argument, the sample ID reflected in the samples filename'
    echo 'For example: Muscle2 would be the argument for processing Muscle2_R1.fastq.gz and Muscle2_R2.fastq.gz'
    echo 'Files expected of name format ${SID}_R1.fastq.gz and ${SID}_R2.fastq.gz'
    exit 0
fi

echo "Entering sampleData Directory"
cd /Users/akre96/Documents/github/rrbs_bismark/sampleData

echo "Activating conda environment: bioinfo"
source activate bioinfo

SID=$1
R1=${SID}_R1.fastq
R2=${SID}_R2.fastq
I1=${SID}_I1.fastq
sampleSize=100000
let "sampleSizeName = sampleSize/1000"
outFileLabel="${sampleSizeName}ksub"


echo "Unzipping ${R1}.gz"
echo "..."
gunzip -c ${R1}.gz > ${R1}
echo "Done."

echo "Unzipping ${R2}.gz"
echo "..."
gunzip -c ${R2}.gz > ${R2}
echo "Done."

echo "Unzipping ${I1}.gz"
echo "..."
gunzip -c ${I1}.gz > ${I1}
echo "Done."

echo "Subsampling ${R1} with ${sampleSize} entries"
echo "..."
seqtk sample -s100 ${R1} ${sampleSize} > ${SID}_${outFileLabel}_R1.fastq 
echo "Done."

echo "Subsampling ${R2} with ${sampleSize} entries"
echo "..."
seqtk sample -s100 ${R2} ${sampleSize} > ${SID}_${outFileLabel}_R2.fastq 
echo "Done."

echo "Subsampling ${I1} with ${sampleSize} entries"
echo "..."
seqtk sample -s100 ${I1} ${sampleSize} > ${SID}_${outFileLabel}_I1.fastq 
echo "Done."

echo "Removing unzipped files ${R1}, ${R2} and ${I1}"
rm ${R1}
rm ${R2}
rm ${I1}

echo "Zipping output with label: ${SID}_${outFileLabel}"
echo "..."
gzip ${SID}_${outFileLabel}_R1.fastq
gzip ${SID}_${outFileLabel}_R2.fastq
gzip ${SID}_${outFileLabel}_I1.fastq
echo "Done."

source deactivate
echo "Conda Environment Deactivated"



