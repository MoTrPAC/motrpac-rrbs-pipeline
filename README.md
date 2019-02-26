# Current RRBS Pipeline Implementation [UNDER PRELIMINARY DEVELOPMENT]
  - Currently modelled after: [MoTrPAC GET Assay and Data Mop](https://docs.google.com/document/d/1xlFiax4MTSzNZS3SpG6i3Z3XwuGkMPgONV1QPTObjcA/edit)
    - Mop Authors: Yongchao Ge, Venugopalan Nair and Stuart Sealfon @ Mount Sinai
  - dockerBuild folder for building docker image hosted at akre96/motrpac_rrbs:v0.1 on dockerhub. Bismark v0.20.0 
  - *_Cromwell.sh files used to run wdl scripts in cromwell
  - Most folders hold individual tasks being tested on data held in sampleData folder

## Building Docker image:
  - `docker build custom_scripts/ -f dockerBuild/Dockerfile -t akre96/motrpack_rrbs:v0.1`

## Requirements (included in Docker image):
  - openjdk/8.0.152
  - python/3.6.6
  - fastqc/0.11.8
  - cutadapt/1.18
  - trim_galore/0.5.0
  - samtools/1.3.1
  - bowtie2/2.3.4.3
  - multiqc/1.6
  - bismark/0.20.0
  - [trimRRBSDiversityAdaptCustomers.py/1.11](https://github.com/nugentechnologies/NuMetRRBS/blob/master/trimRRBSdiversityAdaptCustomers.py)
  - [UMI_attach.awk](https://github.com/yongchao/motrpac_rnaseq/blob/master/bin/UMI_attach.awk)
  - [bismark_bam_UMI_format.awk](https://github.com/yongchao/motrpac_rrbs/blob/master/bin/bismark_bam_UMI_format.awk)
  - [bismark_bam_UMI_format.sh](https://github.com/yongchao/motrpac_rrbs/blob/master/bin/bismark_bam_UMI_format.sh)


## Organization:
  - Index_Genomes: Bisulfite indexing of a given genome
  - Trim_Reads: Fastqc, multiqc, attaching UMI information, and trimming of RRBS data
  - Align_Trimmed: Align RRBS reads to bisulfite indexed genome using bismark and bowtie2
  - Mark_Duplicates: removal of PCR duplicates based on UMI
  - Quantify_Methylation: Use bismark to quantify methylation
  - rrbs_pipeline.wdl: End to end pipeline for single paired end RRBS sample
  - external-scripts: scripts written to generate some sample data, also includes submodules to packages that contain scripts included in the docker image.


## TODO Notes:
  - Right now the scripts in for trimming reads expect a file with .gz output, I will need to figure out how to best allow scripts to be more agnostic to the specific form of the input since the actual packages can run on zipped and unzipped files with no additional specifications required.
  - Check if .gitmodules should be in repository
  - Implement alignment and genome indexing s.t they are not preemptible instances
  - Change default num_threads to increments of 8 to match GClouds vCPUs

# Source files:
[Rat Genome GTF File Release 92](http://ftp.ensembl.org/pub/release-92/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.92.gtf.gz)

[Rat Genome File Release 92](http://ftp.ensembl.org/pub/release-92/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz)

[Human GTF Files Release 29](https://www.gencodegenes.org/human/)
