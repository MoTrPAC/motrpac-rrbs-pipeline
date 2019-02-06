LOCALDIR=/Users/akre96/Documents/github/rrbs_bismark/Index_Genomes
cd $LOCALDIR

## Run on cloud
#java -Dconfig.file=google.conf -jar ~/cromwell/cromwell-36.jar run Bismark_IndexGenomes.wdl -i IndexGenomes_inputs_GCloud.json

## Run locally (test)
java -jar ~/cromwell/cromwell-36.jar run Bismark_IndexGenomes.wdl -i IndexGenomes_inputs_Local.json

# Rat GTF File http://ftp.ensembl.org/pub/release-92/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.92.gtf.gz
# Rat Genome File http://ftp.ensembl.org/pub/release-92/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz

# Human GTF File ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.chr_patch_hapl_scaff.annotation.gtf.gz
# Human Genome File ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/GRCh38.p12.genome.fa.gz
