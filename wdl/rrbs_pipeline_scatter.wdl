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
        File spike_in_genome_tar

        String output_report_name
    }

    meta {
        task_labels: {
            pretrim_fastqc: {
                task_name: "Pre-Trim FastQC",
                description: "Run FastQC on raw reads before adapter trimming to assess how the sequencing quality changes with the actual run cycle number"
            },
            aumi: {
                task_name: "AttachUMI",
                description: "Append the UMI index from I1 file to the read names of R1 and R2 FASTQ files so that the UMI info for each read can be tracked for downstream analysis"
            },
            trim_reg_adapt: {
                task_name: "Trim Galore",
                description: "Adapter trimming of regular adapters"
            },
            trim_diversity_adapt: {
                task_name: "Trim Diversity Adaptors",
                description: "Adapter trimming of NuGen-specific adapters"
            },
            posttrim_fastqc: {
                task_name: "Post-Trim FastQC",
                description: "Post-Trim FastQC to collect metrics related to the library quality such as GC content and duplicated sequences"
            },
            mqc: {
                task_name: "MultiQC",
                description: "MultiQC consolidates logs from Trim Galore, Pre-Trim, and Post-Trim FASTQC steps"
            },
            align_trim_sample: {
                task_name: "Align Trimmed Reads - Sample",
                description: "Align each pair of trimmed FastQ files from each sample to species of interest"
            },
            align_trim_spike_in: {
                task_name: "Align Trimmed Reads - Spike In",
                description: "Align each pair of trimmed FastQ files from each sample to lambda for control"
            },
            tag_udup_sample: {
                task_name: "Tag UMI Duplications - Sample",
                description: "Tag UMI duplications in the aligned BAM files from each sample"
            },
            tag_udup_spike_in: {
                task_name: "Tag UMI Duplications - Spike In",
                description: "Tag UMI duplications in the aligned BAM files of each sample's spike in"
            },
            mark_dup_sample: {
                task_name: "Mark Duplicates - Sample",
                description: "Run MarkDuplicates function from Picard tools on STAR-aligned BAM files to assess PCR duplication in sample based on position of the mapped reads"
            },
            mark_dup_spike_in: {
                task_name: "Mark Duplicates - Spike In",
                description: "Run MarkDuplicates function from Picard tools on STAR-aligned BAM files to assess PCR duplication in spike in based on position of the mapped reads"
            },
            quant_methyl_sample: {
                task_name: "Quantify Methylation - Sample",
                description: "Quantify Methylation for sample"
            },
            quant_methyl_spike_in: {
                task_name: "Quantify Methylation - Spike In",
                description: "Quantify Methylation for Lambda control spike in"
            },
            bowtie2_phix: {
                task_name: "Bowtie2 PHIX",
                description: "Map reads to phix using bowtie2 to compute percentage of phix"
            },
            chrinfo: {
                task_name: "SAMTools Mapped",
                description: "Compute mapping percentages to different chromosomes using SAMTools"
            },
            rnaqc: {
                task_name: "Collect RNAseq Metrics",
                description: "Run CollectRnaSeqMetrics function from Picard tools to capture RNA-seq QC metrics like % reads mapped to coding, intron, inter-genic, UTR, % correct strand, and 5’ to 3’ bias "
            },
            merge_results: {
                task_name: "Merge Results",
                description: "Merges reports and QC metrics files of all the steps from all samples run by the pipeline"
            }
        }
    }

    scatter (i in range(length(r1))) {
        ## Runs FastQC pre-trimming
        call fastqc.fastQC as pretrim_fastqc {
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
        call attach_umi.attachUMI as aumi {
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
        call trim_galore.trimGalore as trim_reg_adapt {
            input:
                memory=40,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1=aumi.r1_umi_attached,
                r2=aumi.r2_umi_attached,
                SID=sample_prefix[i]
        }

        # NuGen specific diversity adapaters trimmed
        call trim_da.trimDiversityAdapt as trim_diversity_adapt {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1_trimmed=trim_reg_adapt.r1_trimmed,
                r2_trimmed=trim_reg_adapt.r2_trimmed,
                SID=sample_prefix[i]
        }

        # FastQC ran on post trimming reads
        call fastqc.fastQC as posttrim_fastqc {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                r1=trim_diversity_adapt.r1_diversity_trimmed,
                r2=trim_diversity_adapt.r2_diversity_trimmed
        }

        # MultiQC on all FastQCs
        call multiqc.multiQC as mqc {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=docker,
                fastQCReports=[pretrim_fastqc.fastQC_report,posttrim_fastqc.fastQC_report],
                trimGalore_report=trim_reg_adapt.trim_log
        }

        # Align trimmed reads to species of interest
        call align_trimmed.alignTrimmed as align_trim_sample {
            # NOT PREEMPTIBLE INSTANCE
            input:
                memory=40,
                disk_space=200,
                num_threads=12,
                num_preempt=0,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_multicore=3,
                r1_trimmed=trim_diversity_adapt.r1_diversity_trimmed,
                r2_trimmed=trim_diversity_adapt.r2_diversity_trimmed,
                genome_dir_tar=genome_dir_tar
        }

        # Align trimmed reads to lambda for control
        call align_trimmed.alignTrimmed as align_trim_spike_in {
            # NOT PREEMPTIBLE INSTANCE
            input:
                memory=40,
                disk_space=200,
                num_threads=12,
                num_preempt=0,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_multicore=3,
                r1_trimmed=trim_diversity_adapt.r1_diversity_trimmed,
                r2_trimmed=trim_diversity_adapt.r2_diversity_trimmed,
                genome_dir_tar=spike_in_genome_tar
        }

        #Tag UMI duplications in sample
        call mark_udup.tag_udup as tag_udup_sample {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=6,
                num_preempt=num_preempt,
                docker=docker,
                SID=sample_prefix[i],
                bismark_reads=align_trim_sample.bismark_reads
        }

        #Tag UMI duplications in spike-in
        call mark_udup.tag_udup as tag_udup_spike_in {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=6,
                num_preempt=num_preempt,
                docker=docker,
                SID=sample_prefix[i],
                bismark_reads=align_trim_spike_in.bismark_reads
        }

        # Remove PCR Duplicates from sample
        call mark_dup.markDuplicates as mark_dup_sample {
            input:
                memory=30,
                disk_space=200,
                num_threads=1,
                num_preempt=num_preempt,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_reads=tag_udup_sample.umi_dup_marked
        }

        # Remove PCR Duplicates from Lambda phage spike in
        call mark_dup.markDuplicates as mark_dup_spike_in {
            input:
                memory=memory,
                disk_space=disk_space,
                num_threads=1,
                num_preempt=num_preempt,
                docker=bismark_docker,
                SID=sample_prefix[i],
                bismark_reads=tag_udup_spike_in.umi_dup_marked
        }

        # Quantify Methylation for sample
        call quant_methyl.quantifyMethylation as quant_methyl_sample {
            input:
                memory=60,
                disk_space=200,
                num_threads=16,
                num_preempt=num_preempt,
                docker=bismark_docker,
                bismark_umi_marked_reads=tag_udup_sample.umi_dup_marked,
                bismark_deduplicated_reads=mark_dup_sample.deduped_bam,
                bismark_dedup_report=mark_dup_sample.dedupLog,
                bismark_alignment_report=align_trim_sample.bismark_report,
                SID=sample_prefix[i]
        }

        # Quantify Methylation for Lambda control spike in
        call quant_methyl.quantifyMethylation as quant_methyl_spike_in {
            input:
                memory=60,
                disk_space=200,
                num_threads=16,
                num_preempt=num_preempt,
                docker=bismark_docker,
                bismark_deduplicated_reads=mark_dup_spike_in.deduped_bam,
                SID=sample_prefix[i],
                bismark_umi_marked_reads=tag_udup_spike_in.umi_dup_marked,
                bismark_dedup_report=mark_dup_spike_in.dedupLog,
                bismark_alignment_report=align_trim_spike_in.bismark_report
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
                fastqr1=trim_reg_adapt.r1_trimmed,
                fastqr2=trim_reg_adapt.r2_trimmed
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
                input_bam=mark_dup_sample.deduped_bam
        }

        # Collect required QC Metrics from reports
        call collect_qc.collectQCMetrics as rnaqc {
            input:
                memory=20,
                disk_space=50,
                num_threads=4,
                num_preempt=0,
                docker=docker,
                SID=sample_prefix[i],
                species_bismark_summary_report=quant_methyl_sample.bismark_summary_report,
                bismark_bt2_pe_report=align_trim_sample.bismark_report,
                multiQC_report=mqc.multiQC_report,
                lambda_bismark_summary_report=quant_methyl_spike_in.bismark_summary_report,
                trim_galore_report=trim_reg_adapt.trim_log,
                trim_diversity_report=trim_diversity_adapt.trim_diversity_log,
                phix_report=bowtie2_phix.bowtie2_report,
                mapping_report=chrinfo.report
        }

    }

    call final_merge.merge_results as merge_results {
        input:
        # Inputs
            output_report_name=output_report_name,
            qc_report_files=rnaqc.qc_metrics,
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

