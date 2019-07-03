FROM continuumio/miniconda3
FROM biocontainers/biocontainers:latest
RUN conda create -n env python=3.6
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

RUN conda install samtools=1.3.1
RUN conda install -c bioconda bismark=0.20.0

# Bismark_bam_UMI_format files from end of January 2019
COPY external-scripts/motrpac_rrbs/bin/bismark_bam_UMI_format.awk /src/
RUN cd /src && \
    chmod 755 bismark_bam_UMI_format.awk && \
    ln -s /src/bismark_bam_UMI_format.awk /usr/local/bin

COPY external-scripts/motrpac_rrbs/bin/bismark_bam_UMI_format.sh /src/
RUN cd /src && \
    chmod 755 bismark_bam_UMI_format.sh && \
    ln -s /src/bismark_bam_UMI_format.sh /usr/local/bin

