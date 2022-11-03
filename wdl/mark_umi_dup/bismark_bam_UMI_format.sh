#!/bin/bash
set -euo pipefail
set -x
bam=$1
sam=${bam%bam}sam
samtools view -h $bam | bismark_bam_UMI_format.awk >$sam
samtools view -b -o $bam $sam
rm $sam
