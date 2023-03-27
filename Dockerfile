#Current version of post external release1 docker gcr.io/my-project/motrpac_rrbs:araja_08_05_2019
#Dockerfile for external release 1 gcr.io/my-project/motrpac_rrbs:araja_07_09_2019
FROM python:3.8-slim-bullseye as compile-image

# Install essentials, python3, python, libraries used for installing other packges, pip, pip3
RUN apt-get update && \
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libncursesw5-dev git wget unzip

WORKDIR /src

# Install Bowtie2-2.3.4.3
RUN wget --progress=dot:giga -O bowtie2.zip https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.4.3/bowtie2-2.3.4.3-linux-x86_64.zip/download && \
	unzip bowtie2.zip && \
    rm -rf /src/bowtie2-2.3.4.3-linux-x86_64/bowtie2*-debug

# Install samtools-1.3.1
RUN wget --progress=dot:giga https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
    tar -vxjf samtools-1.3.1.tar.bz2 && \
    cd samtools-1.3.1 && \
    make

# Install FastQC-0.11.8 
RUN wget --progress=dot:giga -O fastqc.zip https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip && \
    unzip fastqc.zip

# Install Trimgalore-0.5.0
RUN wget --progress=dot:giga -O trimgalore.zip https://github.com/FelixKrueger/TrimGalore/archive/0.5.0.zip && \
    unzip trimgalore.zip

# Install cutadapt-1.18 (for Trimgalore) and multiQC and pandas
RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install pyyaml==5.4.1 cutadapt==1.18 multiQC==1.6 pandas==1.5.1

FROM python:3.8-slim-bullseye

# Install gawk to make awk scripts able to use gensub command, and procps (to get free and top) openjdk-8
RUN apt-get update && \
    apt-get -y install --no-install-recommends gawk procps openjdk-11-jre libtbb-dev perl python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=compile-image /src/bowtie2-2.3.4.3-linux-x86_64/bowtie2* /usr/local/bin/
COPY --from=compile-image /src/samtools-1.3.1/samtools /usr/local/bin/
COPY --from=compile-image /src/TrimGalore-0.5.0/trim_galore /usr/local/bin/
COPY --from=compile-image /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --from=compile-image /usr/local/bin/cutadapt /usr/local/bin/
COPY --from=compile-image /usr/local/bin/multiqc /usr/local/bin/
COPY --from=compile-image /src/FastQC /usr/local/lib/FastQC
RUN ln -s /usr/local/lib/FastQC/fastqc /usr/local/bin/fastqc

RUN chmod 755 /usr/local/bin/bowtie2* && \
    chmod 755 /usr/local/bin/samtools && \
    chmod 755 /usr/local/bin/fastqc && \
    chmod 755 /usr/local/bin/trim_galore

## Adding items from context to docker image
WORKDIR /src

# Install motrpac UMI_attach script
COPY vendor/motrpac_rnaseq/wdl/attach_umi/UMI_attach.awk /src/
RUN chmod 755 UMI_attach.awk && \
    ln -s /src/UMI_attach.awk /usr/local/bin

# strip_bismark_sam.sh specific version
COPY vendor/NuMetRRBS/strip_bismark_sam.sh /src/
RUN chmod 755 strip_bismark_sam.sh && \
    ln -s /src/strip_bismark_sam.sh /usr/local/bin

# trimRRBSdiversityAdaptCustomers.py from July 2018
COPY vendor/NuMetRRBS/trimRRBSdiversityAdaptCustomers.py /src/
RUN chmod 755 trimRRBSdiversityAdaptCustomers.py && \
    ln -s /src/trimRRBSdiversityAdaptCustomers.py /usr/local/bin

# Bismark_bam_UMI_format files from end of January 2019
COPY wdl/mark_umi_dup/bismark_bam_UMI_format.awk /src/
RUN chmod 755 bismark_bam_UMI_format.awk && \
    ln -s /src/bismark_bam_UMI_format.awk /usr/local/bin

COPY wdl/mark_umi_dup/bismark_bam_UMI_format.sh /src/
RUN chmod 755 bismark_bam_UMI_format.sh && \
    ln -s /src/bismark_bam_UMI_format.sh /usr/local/bin

# Script for collecting QC metrics from logs created during pipeline execution
COPY wdl/collect_qc_metrics/collect_qc_metrics.py /src/
RUN chmod 755 collect_qc_metrics.py && \
    ln -s /src/collect_qc_metrics.py /usr/local/bin

# Script for consolidating QC metrics from logs created during pipeline execution
COPY wdl/merge_results/consolidate_qc_report.py /src/
RUN chmod 755 consolidate_qc_report.py && \
    ln -s /src/consolidate_qc_report.py /usr/local/bin

WORKDIR /data
