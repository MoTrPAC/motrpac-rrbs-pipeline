version 1.0

import "trim_reads/tasks/trimGalore.wdl" as trim_galore
import "trim_reads/tasks/trimDiversityAdapt.wdl" as trim_da
import "trim_reads/tasks/fastQC.wdl" as fastqc
import "trim_reads/tasks/multiQC.wdl" as multiqc
import "trim_reads/tasks/attachUMI.wdl" as attach_umi
import "align_trimmed/align_trimmed.wdl" as align_trimmed
import "mark_duplicates/mark_duplicates.wdl" as mark_dup
import "mark_umi_dup/mark_udup.wdl" as mark_udup
import "quantify_methylation/quantify_methylation.wdl" as quant_methyl
import "bowtie2_align/bowtie2_align.wdl" as bowtie2_align
import "compute_mapped/chr_info.wdl" as mapped
import "collect_qc_metrics/collect_qc_metrics.wdl" as collect_qc
import "merge_results/merge_results.wdl" as final_merge

workflow rrbs_pipeline {
    input {
        # Default values for runtime, changed in individual calls according to requirements
        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
        String docker
        String bismark_docker
        Array[File] r1
        Array[File] r2
        Array[File] i1
        Array [String] sample_prefix=[]

        File genome_dir_tar
        String genome_dir # Name of the genome folder that has been tar balled

        File spike_in_genome_tar
        String spike_in_genome_dir

        String output_report_name
    }

    scatter (i in range(length(r1))) {
        ## Runs FastQC pre-trimming
        call fastqc.fastQC as preTrimFastQC {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1=r1[i],
                r2=r2[i]
        }

        # Attach UMI Information
        call attach_umi.attachUMI as attachUMI {
            input:
                memory=40,
                disk_space=disk_space,
                num_threads=8,
                num_preempt=num_preempt,
                docker=docker,
                SID=sample_prefix[i],
                r1=r1[i],
                r2=r2[i],
                i1=i1[i]
        }

        # Trim Galore removes regular adapters
        call trim_galore.trimGalore as trimGalore {
            input:
                memory=40,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1=attachUMI.r1_umi_attached,
                r2=attachUMI.r2_umi_attached,
                SID=sample_prefix[i]
        }

        # NuGen specific diversity adapaters trimmed
        call trim_da.trimDiversityAdapt as trimDiversityAdapt {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1_trimmed=trimGalore.r1_trimmed,
                r2_trimmed=trimGalore.r2_trimmed,
                SID=sample_prefix[i]
        }

        # FastQC ran on post trimming reads
        call fastqc.fastQC as postTrimFastQC {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1=trimDiversityAdapt.r1_diversity_trimmed,
                r2=trimDiversityAdapt.r2_diversity_trimmed
        }

        # MultiQC on all FastQCs
        call multiqc.multiQC as multiQC {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                fastQCReports=[preTrimFastQC.fastQC_report,postTrimFastQC.fastQC_report],
                trimGalore_report=trimGalore.trim_log
        }

        # Align trimmed reads to species of interest
        call align_trimmed.alignTrimmed as alignTrimmedSample {
            # NOT PREEMPTIBLE INSTANCE
            input:
                memory=40,
                disk_space=200,
                num_threads=12,
                num_preempt=0,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_multicore=3,
                r1_trimmed=trimDiversityAdapt.r1_diversity_trimmed,
                r2_trimmed=trimDiversityAdapt.r2_diversity_trimmed,
                genome_dir=genome_dir,
                genome_dir_tar=genome_dir_tar
        }

        # Align trimmed reads to lambda for control
        call align_trimmed.alignTrimmed as alignTrimmedSpikeIn {
            # NOT PREEMPTIBLE INSTANCE
            input:
                memory=40,
                disk_space=200,
                num_threads=12,
                num_preempt=0,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_multicore=3,
                r1_trimmed=trimDiversityAdapt.r1_diversity_trimmed,
                r2_trimmed=trimDiversityAdapt.r2_diversity_trimmed,
                genome_dir=spike_in_genome_dir,
                genome_dir_tar=spike_in_genome_tar
        }

        #Tag UMI duplications in sample
        call mark_udup.tag_udup as tagUMIdupSample {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=6,
                num_preempt=num_preempt,
                docker=docker,
                SID=sample_prefix[i],
                bismark_reads=alignTrimmedSample.bismark_reads
        }

        #Tag UMI duplications in spike-in
        call mark_udup.tag_udup as tagUMIdupSpikeIn {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=6,
                num_preempt=num_preempt,
                docker=docker,
                SID=sample_prefix[i],
                bismark_reads=alignTrimmedSpikeIn.bismark_reads
        }

        # Remove PCR Duplicates from sample
        call mark_dup.markDuplicates as markDuplicatesSample {
            input:
                memory=30,
                disk_space=200,
                num_threads=1,
                num_preempt=num_preempt,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_reads=tagUMIdupSample.umi_dup_marked
        }

        # Remove PCR Duplicates from Lambda phage spike in
        call mark_dup.markDuplicates as markDuplicatesSpikeIn {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_reads=tagUMIdupSpikeIn.umi_dup_marked
        }

        # Quantify Methylation for sample
        call quant_methyl.quantifyMethylation as quantifyMethylationSample {
            input:
                memory=60,
                disk_space=200,
                num_threads=16,
                num_preempt=num_preempt,
                docker=bismark_docker,
                bismark_umi_marked_reads=tagUMIdupSample.umi_dup_marked,
                bismark_deduplicated_reads=markDuplicatesSample.deduped_bam,
                bismark_dedup_report=markDuplicatesSample.dedupLog,
                bismark_alignment_report=alignTrimmedSample.bismark_report,
                SID=sample_prefix[i]
        }

        # Quantify Methylation for Lambda control spike in
        call quant_methyl.quantifyMethylation as quantifyMethylationSpikeIn {
            input:
                memory=60,
                disk_space=200,
                num_threads=16,
                num_preempt=num_preempt,
                docker=bismark_docker,
                bismark_deduplicated_reads=markDuplicatesSpikeIn.deduped_bam,
                SID=sample_prefix[i],
                bismark_umi_marked_reads=tagUMIdupSpikeIn.umi_dup_marked,
                bismark_dedup_report=markDuplicatesSpikeIn.dedupLog,
                bismark_alignment_report=alignTrimmedSpikeIn.bismark_report
        }

        # Align trimGalore trimmed reads to phix genome using bowtie
        call bowtie2_align.bowtie2_align as bowtie2_phix {
            input :
                memory=40,
                disk_space=200,
                num_threads=10,
                num_preempt=0,
                docker=docker,
                SID=sample_prefix[i],
                fastqr1=trimGalore.r1_trimmed,
                fastqr2=trimGalore.r2_trimmed
        }

        # Compute % mapped to chromosomes and contigs
        call mapped.samtools_mapped as chrinfo {
            input:
                num_threads=8,
                memory=30,
                disk_space=200,
                num_preempt=0,
                docker=docker,
                SID=sample_prefix[i],
                input_bam=markDuplicatesSample.deduped_bam
        }

        # Collect required QC Metrics from reports
        call collect_qc.collectQCMetrics as collectQCMetrics {
            input:
                memory=20,
                disk_space=50,
                num_threads=4,
                num_preempt=0,
                docker=docker,
                SID=sample_prefix[i],
                species_bismark_summary_report=quantifyMethylationSample.bismark_summary_report,
                bismark_bt2_pe_report=alignTrimmedSample.bismark_report,
                multiQC_report=multiQC.multiQC_report,
                lambda_bismark_summary_report=quantifyMethylationSpikeIn.bismark_summary_report,
                trim_galore_report=trimGalore.trim_log,
                trim_diversity_report=trimDiversityAdapt.trim_diversity_log,
                phix_report=bowtie2_phix.bowtie2_report,
                mapping_report=chrinfo.report
        }

    }

    call final_merge.merge_results as merge_results {
        input:
        # Inputs
            output_report_name=output_report_name,
            qc_report_files=collectQCMetrics.qc_metrics,
        # Runtime Parameters
            ncpu=2,
            memory=8,
            disk_space=10,

            docker=docker,
    }

    output {
        File qc_report = merge_results.qc_report
    }
}

