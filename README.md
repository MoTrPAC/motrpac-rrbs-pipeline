# Current RRBS Pipeline Implementation [UNDER PRELIMINARY DEVELOPMENT]
  - dockerBuild folder for building docker image hosted at akre96/bismark on dockerhub. Bismark v0.20.0 (not currently being used)
  - *_Cromwell.sh files used to run wdl scripts in cromwell
  - Most folders holds individual tasks being tested on Mout Sinai Muscle data, held in sampleData folder
    - i.e. Index_Genomes subfolder has scripts for indexing the genomes, etc.
    - Trim_Reads and Index_Genomes preliminarily complete. Creating WDL tasks for each section, attempts to tie them together failing
    - Issues with [NuGen Diersity Trimming Scripts](https://github.com/nugentechnologies/NuMetRRBS)
        - trimDiversityAdapters python script by NuGen running, but I can't find any output files, need to run outside of cromwell to check if it works and cromwell is just deleting the file
        - Update(1/10/19): After running outside cromwell, found out that the python script creates the output files in the same directory as the input files, regardless of where the script is run from. Created a custom version of NuGen's script that allows for the specification of an output directory.
    - Align_Trimmed still in progress, rough skeleton of workflow done. Need to create reduced size test genome before I can/should proceed.


# TODO Notes:
  - Right now the scripts in for trimming reads expect a file with .gz output, I will need to figure out how to best allow scripts to be more agnostic to the specific form of the input since the actual packages can run on zipped and unzipped files with no additional specifications required.

# Source files:
[Rat Genome GTF File](http://ftp.ensembl.org/pub/release-92/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.92.gtf.gz)

[Rat Genome File](http://ftp.ensembl.org/pub/release-92/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz)

[Human GTF File](ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.chr_patch_hapl_scaff.annotation.gtf.gz)

[Human Genome File](ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/GRCh38.p12.genome.fa.gz)
