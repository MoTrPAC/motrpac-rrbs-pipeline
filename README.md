# Current RRBS Pipeline Implementation [UNDER PRELIMINARY DEVELOPMENT]
  - dockerBuild folder for building docker image hosted at akre96/motrpac_rrbs:v0.1 on dockerhub. Bismark v0.20.0 
  - *_Cromwell.sh files used to run wdl scripts in cromwell
  - Most folders holds individual tasks being tested on data held in sampleData folder


# TODO Notes:
  - Right now the scripts in for trimming reads expect a file with .gz output, I will need to figure out how to best allow scripts to be more agnostic to the specific form of the input since the actual packages can run on zipped and unzipped files with no additional specifications required.
  - Check if .gitmodules should be in repository

# Source files:
[Rat Genome GTF File Release 92](http://ftp.ensembl.org/pub/release-92/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.92.gtf.gz)

[Rat Genome File Release 92](http://ftp.ensembl.org/pub/release-92/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz)

[Human GTF Files Release 29](https://www.gencodegenes.org/human/)
