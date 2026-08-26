MoTrPAC RRBS Pipeline
=================================================

[![DOI](https://zenodo.org/badge/161703075.svg)](https://zenodo.org/badge/latestdoi/161703075)

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [GCP Set-up](#gcp-set-up)
- [Software / Dockerfiles](#software--dockerfiles)
- [Configuration Files](#configuration-files)
- [Run the Pipeline](#run-the-pipeline)
- [Pipeline Outputs](#pipeline-outputs)
- [Monitoring and Job Management](#monitoring-and-job-management)
- [WDL Workflow Structure](#wdl-workflow-structure)
- [Troubleshooting](#troubleshooting)
- [Utilities and Helper Scripts](#utilities-and-helper-scripts)
- [Citations and References](#citations-and-references)
- [Contributing and Support](#contributing-and-support)
- [Version Information](#version-information)
- [License](#license)

## Overview

This repo contains the Reduced Representation Bisulfite Sequencing (RRBS) data processing pipeline implemented in Workflow Description Language (WDL) based on harmonized [MOP](http://study-docs.motrpac-data.org/Animal_GET_MOP.pdf). This pipeline uses [caper](https://github.com/MoTrPAC/caper), a wrapper python package for the workflow management system [Cromwell](https://cromwell.readthedocs.io/en/stable/). All the data was processed on the Google Cloud Platform (GCP).

### RRBS Method Overview

**Reduced Representation Bisulfite Sequencing (RRBS)** is a cost-effective method for analyzing DNA methylation at single-base resolution. RRBS enriches for CpG-rich regions by using restriction enzymes (typically MspI) to digest genomic DNA before bisulfite conversion, focusing sequencing on regulatory regions while reducing sequencing costs compared to whole-genome bisulfite sequencing.

### Pipeline Tools

The pipeline uses:
- [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) for alignment and quantification of methylation levels
- [Trim Galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) for adapter trimming
- Quality control tools including FastQC and MultiQC
- Lambda phage spike-in for bisulfite conversion efficiency assessment
- Bowtie2 for contamination screening (PhiX)
- Custom diversity adapter trimming for RRBS-specific adapters

### Pipeline Features

The pipeline:
- Processes paired-end FASTQ files with UMI (Unique Molecular Identifier) support
- Trims RRBS diversity adapters and regular Illumina adapters
- Performs bisulfite-converted read alignment to reference genome
- Quantifies methylation levels at CpG sites
- Assesses bisulfite conversion efficiency using lambda phage spike-in
- Generates comprehensive QC metrics for outlier detection and covariate adjustment

### Pipeline Outputs

The pipeline generates:
- Methylation quantification (coverage files) at CpG sites
- Bismark alignment BAM files
- Lambda spike-in control metrics for conversion efficiency
- Comprehensive QC metrics including conversion efficiency, coverage, and duplication rates
- MultiQC reports for quality assessment

### Supported Organisms

- **Rat**: rn6 (Rnor_6.0), rn7 (mRatBN7.2)

## Quick Start

For experienced users, here's the essential workflow:

```bash
# 1. Clone the repository
git clone https://github.com/MoTrPAC/motrpac-rrbs-pipeline

# 2. Install Python dependencies
pip3 install -r scripts/requirements.txt

# 3. Generate input JSON configuration
python3 scripts/make_json_rrbs.py \
  -g gs://your-bucket/rrbs/batch1/fastq_raw \
  -o ./input_json \
  -r batch1_qc_metrics \
  -a rat-rn7 \
  -n 1 \
  -d us-docker.pkg.dev/motrpac-portal/rrbs \
  -p your-gcp-project

# 4. Submit the pipeline
caper submit wdl/rrbs_pipeline_scatter.wdl -i input_json/set1_rrbs.json

# 5. Monitor pipeline status
caper list
```

## Prerequisites

### Required Accounts
- Google Cloud Platform (GCP) account with billing enabled
- GCP service account with appropriate permissions
- GCP Storage bucket for pipeline inputs and outputs

### Required Software (Local Machine)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Python >= 3.6.9
- Git

### Python Dependencies

Install required Python packages:
```bash
pip3 install -r scripts/requirements.txt
```

The main dependencies include:
- `gcsfs` - for accessing Google Cloud Storage
- `numpy` - for data processing

### Required Input Files

For each sample, you need:
- **R1 FASTQ file** - Forward reads (paired-end)
- **R2 FASTQ file** - Reverse reads (paired-end)
- **I1 FASTQ file** - Index reads containing UMI sequences

File naming convention:
- R1: `{sample_name}_R1.fastq.gz`
- R2: `{sample_name}_R2.fastq.gz`
- I1: `{sample_name}_I1.fastq.gz`

### GCP Permissions and APIs

Ensure the following APIs are enabled in your GCP project:
- Compute Engine API
- Cloud Storage API
- Cloud Life Sciences API (for workflow execution)

## GCP Set-up

The WDL/Cromwell framework is optimized to run pipelines in high-performance computing environments. The MoTrPAC Bioinformatics Center runs pipelines on Google Cloud Platform (GCP). We used a number of wrapper tools developed by our colleagues from the [ENCODE project](https://github.com/ENCODE-DCC) to run pipelines on GCP (and other HPC platforms).

A brief summary of the steps to set-up a VM to run the Motrpac pipelines on GCP (**for details, please, check the [caper repo](https://github.com/MoTrPAC/caper/blob/master/scripts/gcp_caper_server/README.md)**):

### Step-by-Step Setup

**1. Create a GCP account**
- Enable billing for your project

**2. Enable cloud APIs**
- Enable required APIs in GCP Console

**3. Install Google Cloud SDK**
- Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) on your local machine
- Authenticate: `gcloud auth login`

**4. Create a service account**
- Create a service account in GCP Console
- Download the key file to your local computer (e.g., "`service-account-191919.json`")

**5. Create a storage bucket**
- Create a bucket for pipeline inputs and outputs (e.g., `gs://rrbs-pipeline/`)
- Note: a GCP bucket is similar to a folder, but stored on Google's servers in the cloud

**6. Set up a VM instance**
- Create a Virtual Machine (VM) instance from where pipelines will be run
- Use the script available in the [caper repo](https://github.com/MoTrPAC/caper/)
- Clone the caper repo on your local machine and run:

```bash
$ bash create_instance.sh [INSTANCE_NAME] [PROJECT_ID] [GCP_SERVICE_ACCOUNT_KEY_JSON_FILE] [GCP_OUT_DIR]

# Example for the pipeline:
./create_instance.sh rrbs-vm your-gcp-project-name service-account-191919.json gs://rrbs-pipeline/results/
```

**7. Clone this repository on the VM**

```bash
git clone https://github.com/MoTrPAC/motrpac-rrbs-pipeline
```

## Software / Dockerfiles

Several tools are required to run the RRBS pipeline. All of them are pre-installed in Docker containers, which are publicly available in the [Artifact Registry](https://cloud.google.com/artifact-registry).

### Available Docker Images

The pipeline uses two main Docker images:

1. **Main RRBS Image** (`us-docker.pkg.dev/motrpac-portal/rrbs/rrbs:msamdars_11_14_2022`)
   - FastQC - Quality control
   - Trim Galore - Adapter trimming
   - MultiQC - Aggregate QC reporting
   - UMI tools - UMI attachment and duplication marking
   - Bowtie2 - Contamination screening
   - SAMtools - BAM file processing
   - Custom diversity adapter trimming tools

2. **Bismark Image** (`us-docker.pkg.dev/motrpac-portal/rrbs/bismark:0.20.0`)
   - Bismark v0.20.0 - Bisulfite-aware aligner and methylation caller
   - Bowtie2 (included with Bismark)

### Building Docker Images Locally

To find out more about the specific versions of tools used to run the pipeline, check the `Dockerfile`.

To build the Docker image locally:
```bash
docker build -t rrbs:latest .
```

### Reference Files

The pipeline uses the following reference files (available on GCS):

**Rat (rn6) References:**
- Bisulfite-converted genome: `gs://omicspipelines/rrbs/references/rat/rat_Bisulfite_Genome.tar.gz`
- Lambda phage (spike-in): `gs://omicspipelines/rrbs/references/lambda/lambda_Bisulfite_Genome.tar.gz`
- PhiX (contamination): `gs://omicspipelines/rnaseq/references/rat/phix.tar.gz`

**Rat (rn7) References:**
- Bisulfite-converted genome: `gs://omicspipelines-public-resources/rrbs/references/rat/rn7/rat_Bisulfite_Genome.tar.gz`
- Lambda phage (spike-in): `gs://omicspipelines-public-resources/rrbs/references/lambda/lambda_Bisulfite_Genome.tar.gz`
- PhiX (contamination): `gs://omicspipelines-public-resources/rnaseq/references/rat/phix.tar.gz`

## Configuration Files

An input configuration file (in JSON format) is required to process the data through the pipeline. This configuration file contains several key-value pairs that specify the inputs and outputs of the workflow, the location of input files, default pipeline parameters, docker containers, execution environment, and other parameters needed for execution.

### Generating Configuration Files

The optimal way to generate configuration files is to run the `make_json_rrbs.py` script.

**Usage:**

```bash
python3 scripts/make_json_rrbs.py \
  -g GCP_PATH \             # GCS path to directory containing FASTQ files
  -o OUTPUT_PATH \          # Local path where JSON files will be written
  -r OUTPUT_REPORT_NAME \   # Name for the output QC metrics report
  -a {rat-rn6,rat-rn7} \    # Organism and genome version
  -n NUM_CHUNKS \           # Number of batches to split samples into
  -d DOCKER_REPO \          # Docker repository prefix (optional)
  -p PROJECT \              # GCP project name
  -u                        # Include undetermined reads (optional)
```

**Parameters:**
- `-g, --gcp_path` - Location of the batch directory in GCS that contains the fastq_raw directory
- `-o, --output_path` - Local output path where JSON files will be written
- `-r, --output_report_name` - Name of the output QC report file
- `-a, --organism` - Organism name (choices: `rat-rn6` or `rat-rn7`, default: `rat-rn7`)
- `-n, --num_chunks` - Number of chunks to split input files (must be ≤ number of input files)
- `-d, --docker_repo` - Docker repository prefix (default: `us-docker.pkg.dev/motrpac-portal/rrbs`)
- `-p, --project` - GCP project name
- `-u, --undetermined` - Include undetermined FASTQ files (files with prefix "Undetermined_")

**Complete Example:**

```bash
python3 scripts/make_json_rrbs.py \
  -g gs://rrbs-pipeline/batch1/fastq_raw \
  -o ./input_json \
  -r batch1_qc_metrics \
  -a rat-rn7 \
  -n 2 \
  -d us-docker.pkg.dev/motrpac-portal/rrbs \
  -p motrpac-project
```

This will create JSON configuration files (e.g., `set1_rrbs.json`, `set2_rrbs.json`) in the specified output directory.

### Configuration Parameters

The generated JSON includes:

**Input Files:**
- `rrbs_pipeline.r1` - Array of R1 FASTQ files
- `rrbs_pipeline.r2` - Array of R2 FASTQ files
- `rrbs_pipeline.i1` - Array of I1 index files (for UMI)
- `rrbs_pipeline.sample_prefix` - Array of sample names

**Reference Genomes:**
- `rrbs_pipeline.sample_genome_dir_tar` - Bismark genome index (rat)
- `rrbs_pipeline.spike_in_genome_dir_tar` - Lambda phage genome
- `rrbs_pipeline.phix_genome_dir_tar` - PhiX genome

**Runtime Parameters:**
- CPU, memory, and disk allocations for each pipeline step
- `rrbs_pipeline.bismark_multicore` - Bismark multicore setting (default: 3)

**Docker Images:**
- `rrbs_pipeline.docker` - Main pipeline image
- `rrbs_pipeline.bismark_docker` - Bismark image

For more details, see the [scripts README](scripts/README.md).

## Run the Pipeline

Connect to the VM and submit the job using the below commands:

### Submitting the Pipeline

```bash
caper submit wdl/rrbs_pipeline_scatter.wdl -i input_json/set1_rrbs.json
```

### Checking Pipeline Status

```bash
# List all workflows
caper list

# Look for "Succeeded" status
caper list | grep Succeeded
```

The pipeline will process multiple samples in parallel using WDL's scatter-gather pattern.

## Pipeline Outputs

The pipeline generates the following main output files for each sample:

### Methylation Quantification Files

1. **Bismark Coverage Files**
   - `{sample}_bismark_bt2_pe.deduplicated.bismark.cov.gz` - Genome-wide CpG methylation coverage
   - Format: chromosome, start, end, methylation percentage, count methylated, count unmethylated

2. **Bismark M-bias Report**
   - `{sample}_bismark_bt2_pe.deduplicated.M-bias.txt` - Methylation bias across read positions

3. **Splitting Report**
   - `{sample}_bismark_bt2_pe.deduplicated_splitting_report.txt` - Context-specific methylation (CpG, CHG, CHH)

### Alignment Files

4. **Deduplicated BAM Files**
   - `{sample}_bismark_bt2_pe.deduplicated.bam` - Final aligned reads with PCR duplicates removed
   - `{sample}_bismark_bt2_pe.deduplicated.bam.bai` - BAM index file

5. **UMI-marked BAM Files**
   - `{sample}_umi_marked.bam` - Reads marked with UMI information

### Lambda Spike-in Control Files

6. **Lambda Methylation Files**
   - Lambda coverage files - Bisulfite conversion efficiency metrics
   - Lambda alignment reports - Spike-in alignment statistics

### Quality Control Files

7. **QC Metrics Report**
   - `{output_report_name}_qc_metrics.csv` - Comprehensive QC metrics including:
     - Bisulfite conversion efficiency (from lambda spike-in)
     - Alignment rates (sample and lambda)
     - PCR duplication rates
     - UMI duplication rates
     - PhiX contamination rates
     - Coverage depth statistics
     - Chromosome mapping percentages

8. **FastQC Reports**
   - Pre-trimming FastQC reports
   - Post-trimming FastQC reports

9. **MultiQC Report**
   - `multiqc_report.html` - Consolidated QC report

### Additional Outputs

10. **Trim Galore Logs**
    - Regular adapter trimming reports
    - Diversity adapter trimming reports

11. **Bismark Reports**
    - Alignment reports
    - Deduplication reports
    - Methylation extraction reports

### Output Organization

Final outputs are written to the GCS bucket specified during pipeline submission. The directory structure follows:
```
cromwell-executions/
└── rrbs_pipeline/
    └── {workflow_id}/
        └── call-{task_name}/
            └── shard-{sample_index}/
                └── execution/
                    └── {output_files}
```

## Monitoring and Job Management

### Checking Pipeline Status

```bash
# List all workflows
caper list

# Check detailed status of a specific workflow
caper metadata [WORKFLOW_ID]
```

### Monitoring Running Jobs

```bash
# View workflows currently running
caper list | grep Running

# Check logs for a specific workflow
caper debug [WORKFLOW_ID]
```

### Managing Workflows

```bash
# Abort a running workflow
caper abort [WORKFLOW_ID]

# Check troubleshooting information
caper troubleshoot [WORKFLOW_ID]
```

### Retrieving Results

Successful pipeline runs will write outputs to your specified GCS bucket. Intermediate files and execution logs are stored in:
- `cromwell-executions/` - Contains all task execution outputs and logs
- `cromwell-workflow-logs/` - Contains workflow-level logs

To copy results from GCS to your local machine:
```bash
# Copy all results for a specific sample
gsutil -m cp -r gs://your-bucket/results/sample1/* ./local_results/

# Copy only coverage files
gsutil -m cp gs://your-bucket/results/*/*.cov.gz ./coverage_files/

# Copy QC metrics report
gsutil -m cp gs://your-bucket/results/*_qc_metrics.csv ./qc_reports/
```

## WDL Workflow Structure

The pipeline is organized as a modular WDL workflow with the following structure:

### Main Workflow
- `wdl/rrbs_pipeline_scatter.wdl` - Main workflow that orchestrates all tasks using a scatter-gather pattern to process multiple samples in parallel

### Task Modules

The pipeline consists of the following task modules (in `wdl/` directory):

**Pre-alignment QC and Processing:**
- `trim_reads/tasks/fastQC.wdl` - Quality control with FastQC (pre- and post-trimming)
- `trim_reads/tasks/attachUMI.wdl` - Attach UMI indices to read names
- `trim_reads/tasks/trimGalore.wdl` - Regular adapter trimming with Trim Galore
- `trim_reads/tasks/trimDiversityAdapt.wdl` - RRBS diversity adapter trimming
- `trim_reads/tasks/multiQC.wdl` - Aggregate QC reporting

**Alignment and Methylation Calling:**
- `align_trimmed/align_trimmed.wdl` - Bismark alignment to sample genome and lambda spike-in
- `mark_umi_dup/mark_udup.wdl` - Mark UMI-based duplicates
- `mark_duplicates/mark_duplicates.wdl` - Remove PCR duplicates with Bismark deduplication
- `quantify_methylation/quantify_methylation.wdl` - Extract methylation calls from aligned reads

**Quality Control:**
- `bowtie2_align/bowtie2_align.wdl` - Bowtie2 alignment to PhiX for contamination screening
- `compute_mapped/chr_info.wdl` - Chromosome mapping statistics
- `collect_qc_metrics/collect_qc_metrics.wdl` - Consolidated QC metrics collection

**Results Aggregation:**
- `merge_results/merge_results.wdl` - Merge QC metrics across all samples

**Reference Building:**
- `index_genomes/Bismark_IndexGenomes.wdl` - Build Bismark genome indices

### Workflow Execution Pattern

The pipeline uses a **scatter-gather pattern**:
1. **Scatter**: Process each sample in parallel
2. **Per-sample tasks**:
   - QC and trimming (regular + diversity adapters)
   - Alignment to sample genome
   - Alignment to lambda spike-in
   - Duplicate marking (UMI and PCR)
   - Methylation quantification
   - Contamination screening
   - QC metrics collection
3. **Gather**: Merge QC reports from all samples

## Troubleshooting

### Common Issues

**1. Pipeline Fails During Submission**
- Verify JSON configuration is valid: `python3 -m json.tool your_config.json`
- Ensure all required input files exist in the specified GCS paths
- Check that service account has permissions to access GCS buckets
- Verify R1, R2, and I1 files follow the correct naming convention

**2. Bismark Alignment Fails**
- Increase memory allocation (default: 40 GB for sample, adjust if needed)
- Check that genome index is properly formatted
- Verify bismark_multicore setting (default: 3)
- Ensure sufficient disk space (default: 200 GB)

**3. Out of Memory Errors**
- Bismark alignment: Increase `align_trim_sample_ramGB` to 60+ GB
- Methylation extraction: Increase `quant_methyl_sample_ramGB` to 80+ GB
- UMI deduplication: Increase `tag_udup_sample_ramGB` to 60+ GB

**4. Out of Disk Space Errors**
- Alignment tasks: Increase `align_trim_sample_disk` to 300+ GB
- Methylation extraction: Increase `quant_methyl_sample_disk` to 300+ GB
- Check that GCS bucket has sufficient quota

**5. Diversity Adapter Trimming Fails**
- Verify RRBS-specific diversity adapters are present in reads
- Check trim_diversity_adapt parameters
- Ensure sufficient memory (default: 40 GB)

**6. Lambda Spike-in Processing Fails**
- Check that lambda genome reference exists
- Verify sufficient reads aligned to lambda (>1000 reads typically needed)
- Ensure lambda spike-in was added to samples during library prep

**7. Low Bisulfite Conversion Efficiency**
- Check lambda spike-in alignment and methylation reports
- Typical conversion efficiency should be >99%
- Low efficiency (<95%) may indicate sample quality issues

**8. Low Coverage**
- Verify RRBS library prep was successful (MspI digestion)
- Check alignment rates (>70% typical for good RRBS samples)
- Review duplication rates (high duplication may indicate low library complexity)

**9. Docker Image Pull Failures**
- Verify you have access to the Artifact Registry
- Check that docker image names/tags are correct in JSON
- Ensure Compute Engine service account has Container Registry Reader role

### Accessing Logs

**Workflow-level logs:**
```bash
# View workflow metadata
caper metadata [WORKFLOW_ID]

# Check troubleshooting info
caper troubleshoot [WORKFLOW_ID]
```

**Task-level logs:**
Navigate to the Cromwell execution directory:
```bash
cd cromwell-executions/rrbs_pipeline/[WORKFLOW_ID]/
# Find specific task directories and check stderr/stdout logs
```

**Bismark-specific logs:**
- Alignment report: `*_PE_report.txt`
- Deduplication report: `*.deduplication_report.txt`
- M-bias report: `*M-bias.txt`
- Splitting report: `*_splitting_report.txt`

**GCP Console:**
- Navigate to Life Sciences API in GCP Console
- View operation logs and details for each task execution

### Quality Control Checks

**Pre-flight checks:**
1. Verify FASTQ files are not corrupted: `zcat file.fastq.gz | head`
2. Check file naming matches expected pattern
3. Confirm reference files are accessible
4. Validate RRBS library was prepared correctly (MspI digestion)

**Post-run checks:**
1. Check bisulfite conversion efficiency (>99% expected)
2. Verify alignment rates (>70% typical for good RRBS samples)
3. Check duplication rates (depends on library complexity)
4. Assess CpG coverage (RRBS targets ~5-10% of genome, CpG-rich regions)
5. Review chromosome mapping distribution

### Getting Help

If issues persist:
1. Check the Cromwell documentation: https://cromwell.readthedocs.io/
2. Review the Caper documentation: https://github.com/MoTrPAC/caper/
3. Check Bismark documentation: https://www.bioinformatics.babraham.ac.uk/projects/bismark/
4. Open an issue on the GitHub repository with:
   - Workflow ID
   - Error messages from logs
   - JSON configuration (with sensitive data removed)
   - Sample QC metrics if available

## Utilities and Helper Scripts

A number of utility scripts are available providing additional functionality:

### Available Utility Scripts

#### 1. `make_json_rrbs.py`
Generates the input configuration file required to run the RRBS pipeline.

[See Configuration Files section](#configuration-files)

#### 2. `compare_qc_reports.py`
Compares QC reports from different pipeline runs to identify differences.

**Usage:**
```bash
python3 scripts/compare_qc_reports.py \
  report1_qc_metrics.csv \
  report2_qc_metrics.csv
```

#### 3. `check_qc_report.R`
R script to validate QC metrics and check for outliers.

**Usage:**
```bash
Rscript scripts/check_qc_report.R qc_metrics.csv
```

#### 4. `createTestDataSample.sh`
Creates test data by subsampling FASTQ files for pipeline testing.

#### 5. `createTestGenome.sh`
Creates a small test genome for pipeline development and testing.

#### 6. `run_rrbs.sh`
Convenience script for running the RRBS pipeline.

#### 7. `rrbs_pipeline_Cromwell.sh`
Alternative pipeline submission script using Cromwell directly.

#### 8. `run_docker.sh`
Script for running Docker containers locally.

For more details, see the [scripts README](scripts/README.md).

## Citations and References

### Pipeline Documentation
- [MoTrPAC MOP](http://study-docs.motrpac-data.org/Animal_GET_MOP.pdf) - Methods of Procedure for animal studies

### Workflow Management
- [Cromwell](https://cromwell.readthedocs.io/en/stable/) - Workflow management system
- [Caper](https://github.com/MoTrPAC/caper/) - Cromwell wrapper for easy workflow execution
- [WDL](https://openwdl.org/) - Workflow Description Language specification

### Analysis Tools
- [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) - Krueger F and Andrews SR. Bismark: a flexible aligner and methylation caller for Bisulfite-Seq applications. Bioinformatics. 2011.
- [Trim Galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) - Wrapper tool for adapter and quality trimming
- [Cutadapt](https://cutadapt.readthedocs.io/) - Martin M. Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet.journal. 2011.
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) - Quality control for high throughput sequence data
- [MultiQC](https://multiqc.info/) - Ewels P, et al. MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics. 2016.
- [Bowtie2](http://bowtie-bio.sourceforge.net/bowtie2/) - Langmead B and Salzberg SL. Fast gapped-read alignment with Bowtie 2. Nature Methods. 2012.
- [SAMtools](http://www.htslib.org/) - Li H, et al. The Sequence Alignment/Map format and SAMtools. Bioinformatics. 2009.

### RRBS Methodology
- Meissner A, et al. Reduced representation bisulfite sequencing for comparative high-resolution DNA methylation analysis. Nucleic Acids Research. 2005.
- Gu H, et al. Preparation of reduced representation bisulfite sequencing libraries for genome-scale DNA methylation profiling. Nature Protocols. 2011.

### Infrastructure
- [ENCODE-DCC](https://github.com/ENCODE-DCC) - Tools and pipelines from the ENCODE Project Consortium

### Reference Genomes
- **Rat rn6**: Ensembl Rnor_6.0
- **Rat rn7**: Ensembl mRatBN7.2
- **Lambda phage**: Lambda phage genome (bisulfite conversion control)

## Contributing and Support

### Reporting Issues

If you encounter bugs or have feature requests, please open an issue on the [GitHub repository](https://github.com/MoTrPAC/motrpac-rrbs-pipeline/issues).

When reporting issues, please include:
- Description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Workflow ID (if applicable)
- Relevant error messages or logs
- JSON configuration (remove sensitive information)
- Sample QC metrics (conversion efficiency, alignment rates, etc.)

### Contact

For questions or support related to the MoTrPAC RRBS pipeline:
- Open an issue on GitHub: https://github.com/MoTrPAC/motrpac-rrbs-pipeline/issues
- Contact the MoTrPAC Bioinformatics Center

### Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request with a clear description of the changes

### Related Repositories

- [MoTrPAC Data Hub](https://motrpac-data.org/) - Access to MoTrPAC datasets
- [MoTrPAC GitHub Organization](https://github.com/MoTrPAC) - Other MoTrPAC analysis pipelines and tools
- [MoTrPAC Methyl Capture Pipeline](https://github.com/MoTrPAC/motrpac-methyl-capture-pipeline) - Related methylation pipeline for targeted capture

## Version Information

### Current Version
This pipeline is actively maintained and updated. Check the [releases page](https://github.com/MoTrPAC/motrpac-rrbs-pipeline/releases) for version history and changelogs.

### Citing This Pipeline

If you use this pipeline in your research, please cite:

[![DOI](https://zenodo.org/badge/161703075.svg)](https://zenodo.org/badge/latestdoi/161703075)

### Tool Versions

Current versions (see Dockerfile for details):
- Bismark: v0.20.0
- Trim Galore: v0.5.0
- FastQC: v0.11.8
- MultiQC: v1.6
- Bowtie2: v2.3.4.3 (also bundled with Bismark)
- SAMtools: v1.3.1

### Compatibility Notes

- **WDL Version**: 1.0
- **Cromwell Version**: Compatible with Cromwell 50+
- **Python Version**: Requires Python >= 3.6.9
- **GCP**: Designed for Google Cloud Platform (adaptable to other backends with Cromwell configuration)

### Change History

Major updates and changes are documented in the repository's commit history. For significant changes:
- Reference genome updates (rn6 → rn7)
- Tool version updates (see Dockerfile for current versions)
- Workflow optimizations and bug fixes
- QC metric additions

Check the [commit history](https://github.com/MoTrPAC/motrpac-rrbs-pipeline/commits/) for detailed changes.

### Known Limitations

- Pipeline is optimized for rat samples (rn6, rn7)
- Requires UMI sequences (I1 index files)
- Designed for RRBS protocol with MspI digestion
- RRBS covers ~5-10% of genome (CpG-rich regions)
- Large disk and memory requirements for bisulfite alignment
- Lambda spike-in required for accurate conversion efficiency assessment

## License

This project is licensed under the terms of the MIT License. Copyright (c) 2025 MoTrPAC.

The MIT License is a permissive open-source license that allows you to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software, provided that the copyright notice and permission notice are included in all copies or substantial portions of the software. The software is provided "as is", without warranty of any kind.

See the [LICENSE.md](LICENSE.md) file for the full license text.
