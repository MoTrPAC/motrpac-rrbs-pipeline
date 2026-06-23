# Preparing Reference Files for the RRBS Pipeline

This document describes how to prepare reference genome files for running the MoTrPAC RRBS pipeline with a new organism or genome build.

The example below uses the rat rn8 (GRCr8) assembly with Ensembl release 115 annotations.

---

## Overview

The RRBS pipeline requires **3 reference files**:

| # | File | Description | How to Create |
|---|------|-------------|---------------|
| 1 | **Bisulfite Genome** | Bisulfite genome index for rat genome | Generate from chr-prefixed genome FASTA |
| 2 | **Lambda Bisulfite Genome** | Bisulfite genome index for lambda genome | Reuse existing |
| 3 | **PhiX index** | Bowtie2 index for PhiX spike-in | Reuse existing |

---

## Current rn8 Reference Files

The rn8 (GRCr8, Ensembl 115) reference files are stored in GCS at:

```
gs://omicspipelines-public-resources/rrbs/references/rat/rn8/
```

| File | Size | Description |
|------|------|-------------|
| `rat_Bisulfite_Genome.tar.gz` | 8.00GiB | Pre-built Bismark bisulfite genome index for alignment of bisulfite-treated sequencing data |

These files were built from Ensembl release 115, with chromosome names converted from Ensembl (`1, X, MT`) to UCSC (`chr1, chrX, chrM`) convention. See [RNA-seq reference documentation](https://github.com/MoTrPAC/motrpac-rna-seq-pipeline/blob/master/README-DATA-REF.md#chromosome-naming-convention) for more details.

Organism-independent reference files are located at:

- `gs://omicspipelines-public-resources/rrbs/references/lambda/lambda_Bisulfite_Genome.tar.gz`
- `gs://omicspipelines-public-resources/rnaseq/references/rat/phix.tar.gz`

---

## Prerequisites

### Required Tools

#### 1. bismark & bowtie2 (bisulfite genome index generation)

Install in conda environment using [miniforge](https://github.com/conda-forge/miniforge):

```bash
# Download miniforge
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"

# Run installer (Linux)
bash Miniforge3-Linux-x86_64.sh
source ~/.bashrc

# Deactivate automatic activation of environments (optional)
conda config --set auto_activate_base false
source ~/.bashrc

# Create environment
mamba create -n bismark_env -c bioconda -c conda-forge bismark bowtie2 -y
```

#### 2. Google Cloud SDK (gcloud storage)

Follow the official installation guide: https://cloud.google.com/sdk/docs/install

**Verify all tools are installed:**

```bash
conda list -n bismark_env          # Should show installed packages in environment
gcloud storage version             # Should show version
```

---

## Step-by-Step Instructions

### Step 1: Download Ensembl Genome FASTA and GTF

See [RNA-seq reference documentation](https://github.com/MoTrPAC/motrpac-rna-seq-pipeline/blob/master/README-DATA-REF.md#step-1-download-ensembl-genome-fasta-and-gtf) for details:

```bash
mkdir rn8/ && cd rn8/

# Download genome FASTA in here (GTF annotation not required but can be included for reference)
```

---

### Step 2: Add `chr` Prefix to Chromosome Names

See [RNA-seq reference documentation](https://github.com/MoTrPAC/motrpac-rna-seq-pipeline/blob/master/README-DATA-REF.md#step-2-add-chr-prefix-to-chromosome-names) for details.

---

### Step 3: Build Bismark Bisulfite Genome Index

Inside the directory where you have the genome FASTA (e.g., `rn8/`), run:

```bash
# Build Bismark index
nohup mamba run -n bismark_env bismark_genome_preparation --bowtie2 --parallel 16 . > bismark_build.log 2>&1 &

# Check if background job finished
ps aux | grep bismark_genome_preparation

# Create compressed tar archive
cd ..
tar -cvzf rat_Bisulfite_Genome.tar.gz rn8/
```

Upload to GCS:

```bash
gcloud storage cp rat_Bisulfite_Genome.tar.gz gs://omicspipelines-public-resources/rrbs/references/rat/rn8/
```

---

## Reference Genome Summary

All reference files stored in GCS use UCSC-style chr-prefixed chromosome names, regardless of the Ensembl source.

| Version | Assembly | Ensembl Release | Chromosome Names (in GCS) |
|---------|----------|-----------------|---------------------------|
| rn6 | Rnor_6.0 | 96 | chr1-chr20, chrX, chrY, chrM |
| rn7 | mRatBN7.2 | 108 | chr1-chr20, chrX, chrY, chrM |
| rn8 | GRCr8 | 115 | chr1-chr20, chrX, chrY, chrM |

---

## References

- Ensembl FTP: https://ftp.ensembl.org/
- UCSC Genome Browser tools: https://hgdownload.soe.ucsc.edu/admin/exe/
