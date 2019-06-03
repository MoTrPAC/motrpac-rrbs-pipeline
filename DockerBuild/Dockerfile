FROM continuumio/miniconda3
RUN conda create -n env python=3.6
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

RUN conda install -c bioconda samtools=1.3.1
RUN conda install -c bioconda bismark=0.20.0

