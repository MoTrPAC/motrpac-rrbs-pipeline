FROM continuumio/miniconda3
FROM biocontainers/biocontainers:latest
RUN conda create -n env python=3.6
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# Install samtools-1.3.1
#RUN cd /src && \
#    wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
#    tar -vxjf samtools-1.3.1.tar.bz2 && \
#    rm samtools-1.3.1.tar.bz2 && \
#    cd samtools-1.3.1 && \
#    make && \
#    ln -s /src/samtools-1.3.1/samtools /usr/local/bin
RUN conda install samtools=1.3.1
#RUN conda install -c bioconda samtools=1.3.1
RUN conda install -c bioconda bismark=0.20.0

