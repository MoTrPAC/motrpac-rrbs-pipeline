LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark/Index_Genomes
cd $LOCALDIR
if [[ $# -eq 0 ]] ; then
    echo 'ERROR: REQUIRED ARGUMENT MISSING'
    echo 'Requires 1 argument: local or gcloud'
    echo 'For example: bash Bismark_IndexGenomes_Cromwell.sh local'
    echo ''
    exit 0
fi

## Run on cloud
if [ $1 == 'gcloud' ]
then
echo 'Running Bismark_IndexGenomes.wdl on GCloud'
java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run Bismark_IndexGenomes.wdl -i IndexGenomes_inputs_GCloud.json
fi

## Run locally (test)
if [ $1 == 'local' ]
then
echo 'Running Bismark_IndexGenomes.wdl on local machine'
java -jar ~/cromwell/cromwell-36.jar run Bismark_IndexGenomes.wdl -i IndexGenomes_inputs_Local.json
fi

# Rat GTF File http://ftp.ensembl.org/pub/release-92/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.92.gtf.gz
# Rat Genome File http://ftp.ensembl.org/pub/release-92/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz

# Human GTF File ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.chr_patch_hapl_scaff.annotation.gtf.gz
# Human Genome File ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/GRCh38.p12.genome.fa.gz
