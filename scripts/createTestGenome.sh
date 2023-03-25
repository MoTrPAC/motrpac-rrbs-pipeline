set -ueo pipefail

if [[ $# -eq 0 ]] ; then
    echo 'Please choose genome directory as first input and desired chromosome as second input'
    exit 0
fi

genomeDir=$1
chromosome=$2
label="chr_${chromosome}"

echo "Entering genomes directory"
cd /Users/akre96/Documents/github/rrbs_bismark/genome_dir

echo "Activating conda environment: bioinfo"
source activate bioinfo

echo "Entering ${genomeDir} Directory"
cd $genomeDir
genomeSeq="*.fa.gz"
annotation="*.gtf.gz"
mkdir $label

echo "Unzipping genome sequence file"
echo "..."
gunzip -c ./${genomeSeq} > ${label}/genome.fa
echo "Done."

echo "Unzipping annotation file"
echo "..."
gunzip -c ./${annotation} > ${label}/annotation.gtf
echo "Done."

echo "Extracting chromosome ${chromosome} to ${label}/${label}_genome.fa and gzipping"
echo "..."
cat ${label}/genome.fa | seqkit grep -p chr${chromosome} > ${label}/${label}_genome.fa
gzip ${label}/${label}_genome.fa
echo "Done."

echo "Extracting chromosome ${chromosome} entries from annotation to ${label}/${label}_annotation.gtf and gzipping"
echo "..."
cat ${label}/annotation.gtf | grep \#\# > ${label}/${label}_annotation.gtf
cat ${label}/annotation.gtf | grep chr${chromosome} >> ${label}/${label}_annotation.gtf
gzip ${label}/${label}_annotation.gtf
echo "Done."

echo "Removing intermediate files"
echo "..."
rm ${label}/genome.fa
rm ${label}/annotation.gtf
echo "Done."



source deactivate
echo "Conda Environment Deactivated"
