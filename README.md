# Current RRBS Pipeline Implementation
  - Currently modelled after: [MoTrPAC GET Assay and Data Mop](https://docs.google.com/document/d/1xlFiax4MTSzNZS3SpG6i3Z3XwuGkMPgONV1QPTObjcA/edit)
    - Mop Authors: Yongchao Ge, Venugopalan Nair and Stuart Sealfon @ Mount Sinai
  - dockerBuild folder for building docker image hosted at akre96/motrpac_rrbs:v0.1 on dockerhub. Bismark v0.20.0 
  - *_Cromwell.sh files used to run wdl scripts in cromwell
  - Most folders hold individual tasks being tested on data held in sampleData folder

## Building Docker image:
  - `docker build . -t gcr.io/motrpac-portal-dev/motrpac_rrbs:SA_03_08_2019`
  - Replace SA_03_08_2019 with whatever tag you would like for the image. I used initials_date since we have yet to decide on a unified versioning schema for docker containers/images
  - Run this command at the root of the github repository (`.` represents that for me)
  - to push run:
    - `docker push gcr.io/motrpac-portal-dev/motrpac_rrbs:SA_03_08_2019` where the tag (everything after the color) should match the tag you built using. 

## Requirements:
Docker Image: [gcr.io/motrpac-portal-dev/motrpac_rrbs:SA_03_08_2019](gcr.io/motrpac-portal-dev/motrpac_rrbs)  
This docker image is based on ubuntu:18.04

  - openjdk/8.0.152
  - python/3.6.7
  - python/2.7.15c
  - fastqc/0.11.8
  - cutadapt/1.18
  - trim_galore/0.5.0
  - samtools/1.9
  - bowtie2/2.3.4.3
  - multiqc/1.7
  - bismark/0.20.1
  - pandas/0.24.1
  - [trimRRBSDiversityAdaptCustomers.py/1.11](https://github.com/nugentechnologies/NuMetRRBS/blob/master/trimRRBSdiversityAdaptCustomers.py)
      - Requires python 2
  - [UMI_attach.awk](https://github.com/yongchao/motrpac_rnaseq/blob/master/bin/UMI_attach.awk)
  - [bismark_bam_UMI_format.awk](https://github.com/yongchao/motrpac_rrbs/blob/master/bin/bismark_bam_UMI_format.awk)
  - [bismark_bam_UMI_format.sh](https://github.com/yongchao/motrpac_rrbs/blob/master/bin/bismark_bam_UMI_format.sh)


## Organization:
  - __index_genomes__: Bisulfite indexing of a given genome
  - __trim_reads__: Fastqc, multiqc, attaching UMI information, and trimming of RRBS data
  - __align_trimmed__: Align RRBS reads to bisulfite indexed genome using bismark and bowtie2
  - __mark_duplicates__: removal of PCR duplicates based on UMI
  - __quantify_methylation__: Use bismark to quantify methylation
  - __rrbs_pipeline.wdl__: End to end pipeline for one paired end RRBS sample
  - __custom_scripts__: scripts for data collection used in context for building docker image
  - __external-scripts__: Includes submodules to packages that contain scripts included in the docker image.
  - __.Dockerfile__: Dockerfile to build the motrpac_rrbs image
  - __.dockerignore__: files to ignore when sending context to the docker daemon during the docker build process

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
  - Currently pipeline requries input files to be named ${Sample_name}_I1.fastq.gz, ${Sample_name}_R1.fastq.gz, ${Sample_name}_R2.fastq.gz
    - May need to change this to allow for flexibility of inputs and such. 
  - I've run the pipeline using data from Mt. Sinai available at `gs://data-tarnsfer-sinai/rrbs_rn/fastq_raw/` . The files are Rat_Muscle_R1.fastq.gz Rat_Muscle_R2.fastq.gz and Rat_Muscle_I1.fastq.gz
    - I don't generate the EXACT same types of outputs as Mt. Sinai, particularly for the qc metrics file, but the values are comporable.
    - Biggest discrepency in outputs is that the %bases_trimmed ( average read length after trimming divided by average read length before trimming) is different between my run and mt. sinai's. This may be due to my use of upgraded software like samtools 1.9 vs 1.3.1. 
  - collect_qc_metrics.py currently outputs a csv file with the metrics. It may be more useful to output as a JSON. This isn't a big change since the data is formatted in a one row pandas DF. Editing the end of the python script should enable quick conversion to JSON.
    - this script also assumes the second pair of entries from multiQC_general_stats.txt are the trimmed reads, and the first pair are the raw reads. This may not hold true IF any changes are made to the order of fastqc inputs to the multiqc task.

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
March 8th, 2019
