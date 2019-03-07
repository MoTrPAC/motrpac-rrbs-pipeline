FROM ubuntu:18.04

# Steps to hopefully force apt-get update to work
RUN apt-get clean && \
  mv /var/lib/apt/lists /tmp && \
  mkdir -p /var/lib/apt/lists/partial && \
  apt-get clean && \
  apt-get update

# Install essentials, python3, python, libraries used for installing other packges, pip, pip3
RUN apt-get update --fix-missing && \
    apt-get install -y build-essential zlib1g-dev libncurses5-dev libncursesw5-dev git wget unzip python3-pip python3-dev libbz2-dev liblzma-dev python-dev python-pip

# Install gawk to make awk scripts able to use gensub command
RUN apt-get -y install gawk

# Install procps (to get free and top)
RUN apt-get install -y procps

# Install Bowtie2-2.3.4.3
RUN apt-get install -y libtbb-dev && \
	mkdir /src && \
	cd /src && \
	wget -O bowtie2.zip https://sourceforge.net/projects/bowtie-bio/files/bowtie2/2.3.4.3/bowtie2-2.3.4.3-linux-x86_64.zip/download && \
	unzip bowtie2.zip && \
  rm bowtie2.zip && \
	ln -s /src/bowtie2-2.3.4.3-linux-x86_64/bowtie2* /usr/local/bin

# Install Bismark-0.20.1
RUN cd /src && \
	wget https://github.com/FelixKrueger/Bismark/archive/0.20.1.tar.gz && \
	tar zxf 0.20.1.tar.gz && \
  rm 0.20.1.tar.gz && \
	ln -s /src/Bismark-0.20.1/bismark* /usr/local/bin/ && \
	ln -s /src/Bismark-0.20.1/dedup* /usr/local/bin/

# Install samtools-1.9
RUN cd /src && \
    wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 && \
    tar -vxjf samtools-1.9.tar.bz2 && \
    rm samtools-1.9.tar.bz2 && \
    cd samtools-1.9 && \
    make && \
    ln -s /src/samtools-1.9/samtools /usr/local/bin

# Install cutadapt-1.18 (for Trimgalore)
RUN pip3 install cutadapt==1.18

# Install openjdk-8
RUN apt-get -y install openjdk-8-jre

# Install FastQC-0.11.8 
RUN cd /src && \
    wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip && \
    unzip fastqc_v0.11.8.zip && \
    rm fastqc_v0.11.8.zip && \
    chmod 755 FastQC/fastqc && \
    ln -s /src/FastQC/fastqc /usr/local/bin

# Install Trimgalore-0.5.0
RUN cd /tmp && \
    wget https://github.com/FelixKrueger/TrimGalore/archive/0.5.0.zip && \
    unzip 0.5.0.zip && \
    cp TrimGalore-0.5.0/trim_galore /usr/local/bin && \
    chmod 755 /usr/local/bin/trim_galore

# Install multiQC-1.7
RUN pip install multiQC==1.7

# Clean up TMP
RUN rm -rf tmp

# Install motrpac UMI_attach script
COPY external_scripts/motrpac_rnaseq/bin/UMI_attach.awk /src/
RUN cd /src && \
    chmod 755 UMI_attach.awk && \
    ln -s /src/UMI_attach.awk /usr/local/bin

# strip_bismark_sam.sh specific version
COPY external_scripts/NuMetRRBS/strip_bismark_sam.sh /src/
RUN cd /src && \
    ln -s /src/strip_bismark_sam.sh /usr/local/bin

# trimRRBSdiversityAdaptCustomers.py from July 2018
COPY external_scripts/NuMetRRBS/trimRRBSdiversityAdaptCustomers.py /src/
RUN cd /src && \
    ln -s /src/trimRRBSdiversityAdaptCustomers.py /usr/local/bin


# Bismark_bam_UMI_format files from end of January 2019
COPY external_scripts/motrpac_rrbs/bin/bismark_bam_UMI_format.awk /src/
RUN cd /src && \
    chmod 755 bismark_bam_UMI_format.awk && \
    ln -s /src/bismark_bam_UMI_format.awk /usr/local/bin

COPY external_scripts/motrpac_rrbs/bin/bismark_bam_UMI_format.sh /src/
RUN cd /src && \
    chmod 755 bismark_bam_UMI_format.sh && \
    ln -s /src/bismark_bam_UMI_format.sh /usr/local/bin

RUN pip3 install pandas==0.24.1


## Adding items from context to docker image

# Script for collecting QC metrics from logs created during pipeline execution
COPY custom_scripts/collect_qc_metrics.py /src/
