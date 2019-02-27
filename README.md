# Current RRBS Pipeline Implementation
  - Currently modelled after: [MoTrPAC GET Assay and Data Mop](https://docs.google.com/document/d/1xlFiax4MTSzNZS3SpG6i3Z3XwuGkMPgONV1QPTObjcA/edit)
    - Mop Authors: Yongchao Ge, Venugopalan Nair and Stuart Sealfon @ Mount Sinai
  - dockerBuild folder for building docker image hosted at akre96/motrpac_rrbs:v0.1 on dockerhub. Bismark v0.20.0 
  - *_Cromwell.sh files used to run wdl scripts in cromwell
  - Most folders hold individual tasks being tested on data held in sampleData folder

## Building Docker image:
  - `docker build custom_scripts/ -f dockerBuild/Dockerfile -t akre96/motrpack_rrbs:v0.1`

## Requirements:
Docker Image: [akre96/motrpac_rrbs:v0.2](https://cloud.docker.com/repository/docker/akre96/motrpac_rrbs/general)  
This docker image is based on ubuntu:18.04

  - openjdk/8.0.152
  - python/3.6.7
  - fastqc/0.11.8
  - cutadapt/1.18
  - trim_galore/0.5.0
  - samtools/1.9
  - bowtie2/2.3.4.3
  - multiqc/1.7
  - bismark/0.20.1
  - pandas/0.24.1
  - [trimRRBSDiversityAdaptCustomers.py/1.11](https://github.com/nugentechnologies/NuMetRRBS/blob/master/trimRRBSdiversityAdaptCustomers.py)
  - [UMI_attach.awk](https://github.com/yongchao/motrpac_rnaseq/blob/master/bin/UMI_attach.awk)
  - [bismark_bam_UMI_format.awk](https://github.com/yongchao/motrpac_rrbs/blob/master/bin/bismark_bam_UMI_format.awk)
  - [bismark_bam_UMI_format.sh](https://github.com/yongchao/motrpac_rrbs/blob/master/bin/bismark_bam_UMI_format.sh)


## Organization:
  - __Index_Genomes__: Bisulfite indexing of a given genome
  - __Trim_Reads__: Fastqc, multiqc, attaching UMI information, and trimming of RRBS data
  - __Align_Trimmed__: Align RRBS reads to bisulfite indexed genome using bismark and bowtie2
  - __Mark_Duplicates__: removal of PCR duplicates based on UMI
  - __Quantify_Methylation__: Use bismark to quantify methylation
  - __rrbs_pipeline.wdl__: End to end pipeline for single paired end RRBS sample
  - __custom_scripts__: scripts for data collection used in context for building docker image
  - __external-scripts__: Includes submodules to packages that contain scripts included in the docker image. [Will be removed soon]

In general the following also holds true:
  - __*\_Cromwell.sh__: files used to run wdl scripts on cromwell engine in the cloud or locally
  - __*\_inputs_Local.json__: inputs to wdl scripts for local usage
  - __*\_inputs_GCloud.json__: inputs to wdl scripts for usage on GCP

## Broad Overview Of Steps For Processing:
### Generating Bisulfite Indexed Genome
Done once on lambda and species being analysed (Human or Rat)
1. Run bismark_genome_perparation on required genomes

### Processing Samples (A broad overview of the steps)
1. Run FastQC on raw reads
2. Attach UMI barcodes (I1) to R1 and R2
3. Trim for both quality and using nugen diversity adapters
    - uses trimGalore and Nugens NuMetRRBS package
4. Run FastQC on processed reads
5. Run MultiQC on raw and processed fastqc outputs
6. Align trimmed reads to lambda genome and species of interest genome
    - Genomes must have been bisulfite converted and indexed
7. Remove PCR duplicates using UMIs for reads aligned to lambda and species genome
8. Quantify methylation based on alignment
    - Lambda genome alignment quantification is used to find bisulfite conversion efficiency
9. Collect QC metrics using logs and reports generated in previous steps

## TODO Notes:
  - Right now the scripts in for trimming reads expect a file with .gz output, I will need to figure out how to best allow scripts to be more agnostic to the specific form of the input since the actual packages can run on zipped and unzipped files with no additional specifications required.
  - Check if .gitmodules should be in repository

## Source files:
### Rat
[Rat Genome File Release 95](http://ftp.ensembl.org/pub/release-95/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna.toplevel.fa.gz)

[Rat Genome GTF File Release 95](http://ftp.ensembl.org/pub/release-95/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.95.gtf.gz)

### Human
[Human Genome File GRCh38 (PRI)](http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/GRCh38.primary_assembly.genome.fa.gz)

[Human GTF File](http://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.primary_assembly.annotation.gtf.gz)

## Lambda
[Lambda Genome](https://www.ncbi.nlm.nih.gov/nuccore/J02459.1)

---
Sincerely,  
Samir Akre  
February 26th, 2019
