import "trim_reads/wdl-tasks/trimGalore.wdl" as TG
import "trim_reads/wdl-tasks/trimDiversityAdapt.wdl" as TDA
import "trim_reads/wdl-tasks/fastQC.wdl" as FQC
import "trim_reads/wdl-tasks/multiQC.wdl" as MQC
import "trim_reads/wdl-tasks/attachUMI.wdl" as AUMI
import "align_trimmed/align_trimmed.wdl" as AT
import "mark_duplicates/mark_duplicates.wdl" as MD
import "mark_umi_dup/mark_udup.wdl" as MU
import "quantify_methylation/quantify_methylation.wdl" as QM
import "bowtie2_align/bowtie2_align.wdl" as BA
import "compute_mapped/chr_info.wdl" as SM
import "collect_qc_metrics/collect_qc_metrics.wdl" as CQCM

workflow rrbs_pipeline{
  # Default values for runtime, changed in individual calls according to requirements
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker
  String bismark_docker
  File r1
  File r2
  File i1
  String SID

  File genome_dir_tar
  String genome_dir # Name of the genome folder that has been tar balled 

  File spike_in_genome_tar
  String spike_in_genome_dir

  ## Runs FastQC pre-trimming 
  call FQC.fastQC as preTrimFastQC {
    input: 
    memory=memory,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt, 
    docker=docker,
    r1=r1,
    r2=r2
  }

  # Attach UMI Information
  call AUMI.attachUMI as attachUMI {
    input: 
    memory=40,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt, 
    docker=docker,
    SID=SID,
    r1=r1,
    r2=r2,
    i1=i1
  }

  # Trim Galore removes regular adapters
  call TG.trimGalore as trimGalore {
    input:
    memory=50,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt,
    docker=docker,
    r1=attachUMI.r1_umi_attached,
    r2=attachUMI.r2_umi_attached,
    SID=SID
    }

  # NuGen specific diversity adapaters trimmed
  call TDA.trimDiversityAdapt as trimDiversityAdapt {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt,
    docker=docker,
    r1_trimmed=trimGalore.r1_trimmed,
    r2_trimmed=trimGalore.r2_trimmed,
    SID=SID
    }

  # FastQC ran on post trimming reads
  call FQC.fastQC as postTrimFastQC {
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
  call MQC.multiQC as multiQC {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt, 
    docker=docker,
    fastQCReports=[preTrimFastQC.fastQC_report,postTrimFastQC.fastQC_report],
    trimGalore_report=trimGalore.trimLog
  }

  # Align trimmed reads to species of interest
  call AT.alignTrimmed as alignTrimmedSample{
    # NOT PREEMPTIBLE INSTANCE
    input:
    memory=50,
    disk_space=200,
    num_threads=24,
    num_preempt=0,
    docker=bismark_docker,
    SID=SID,
    bismark_multicore=6,
    r1_trimmed=trimDiversityAdapt.r1_diversity_trimmed,
    r2_trimmed=trimDiversityAdapt.r2_diversity_trimmed,
    genome_dir=genome_dir,
    genome_dir_tar=genome_dir_tar
  }

  # Align trimmed reads to lambda for control
  call AT.alignTrimmed as alignTrimmedSpikeIn{
    # NOT PREEMPTIBLE INSTANCE
    input:
    memory=50,
    disk_space=200,
    num_threads=24,
    num_preempt=0,
    docker=bismark_docker,
    SID=SID,
    bismark_multicore=6,
    r1_trimmed=trimDiversityAdapt.r1_diversity_trimmed,
    r2_trimmed=trimDiversityAdapt.r2_diversity_trimmed,
    genome_dir=spike_in_genome_dir,
    genome_dir_tar=spike_in_genome_tar
  }

  #Tag UMI duplications in sample
   call MU.tag_udup as tagUMIdupSample{
     input:
     memory=memory,
     disk_space=disk_space,
     num_threads=6,
     num_preempt=num_preempt,
     docker=docker,
     SID=SID,
     bismark_reads=alignTrimmedSample.bismark_reads
  }

  #Tag UMI duplications in spike-in
  call MU.tag_udup as tagUMIdupSpikeIn{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=6,
    num_preempt=num_preempt,
    docker=docker,
    SID=SID,
    bismark_reads=alignTrimmedSpikeIn.bismark_reads
  }

  # Remove PCR Duplicates from sample
  call MD.markDuplicates as markDuplicatesSample {
    input:
    memory=30,
    disk_space=200,
    num_threads=1,
    num_preempt=num_preempt,
    docker=bismark_docker,
    SID=SID,
    bismark_reads=tagUMIdupSample.umi_dup_marked
    } 

  # Remove PCR Duplicates from Lambda phage spike in
  call MD.markDuplicates as markDuplicatesSpikeIn{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt,
    docker=bismark_docker,
    SID=SID,
    bismark_reads=tagUMIdupSpikeIn.umi_dup_marked
    } 
  
  # Quantify Methylation for sample
  call QM.quantifyMethylation as quantifyMethylationSample {
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
    SID=SID
    }

  # Quantify Methylation for Lambda control spike in
  call QM.quantifyMethylation as quantifyMethylationSpikeIn{
    input:
    memory=60,
    disk_space=200,
    num_threads=16,
    num_preempt=num_preempt,
    docker=bismark_docker,
    bismark_deduplicated_reads=markDuplicatesSpikeIn.deduped_bam,
    SID=SID,
    bismark_umi_marked_reads=tagUMIdupSpikeIn.umi_dup_marked,
    bismark_dedup_report=markDuplicatesSpikeIn.dedupLog,
    bismark_alignment_report=alignTrimmedSpikeIn.bismark_report
    }

  # Align trimGalore trimmed reads to phix genome using bowtie
  call BA.bowtie2_align as bowtie2_phix {
    input :
    memory=40,
    disk_space=200,
    num_threads=10,
    num_preempt=0,
    docker=docker,
    SID=SID,
    fastqr1=trimGalore.r1_trimmed,
    fastqr2=trimGalore.r2_trimmed
    }

  # Compute % mapped to chromosomes and contigs
  call SM.samtools_mapped as chrinfo {
    input:
    num_threads=8,
    memory=30,
    disk_space=200,
    num_preempt=0,
    docker=docker,
    SID=SID,
    input_bam=markDuplicatesSample.deduped_bam
  }
   
  # Collect required QC Metrics from reports
  call CQCM.collectQCMetrics as collectQCMetrics {
    input:
    memory=20,
    disk_space=50,
    num_threads=1,
    num_preempt=0,
    docker=docker,
    SID=SID,
    species_bismark_summary_report=quantifyMethylationSample.bismark_summary_report,
    bismark_bt2_pe_report=alignTrimmedSample.bismark_report,
    deduplication_report=markDuplicatesSample.dedupLog,
    multiQC_report=multiQC.multiQC_report,
    lambda_bismark_summary_report=quantifyMethylationSpikeIn.bismark_summary_report,
    dedup_report_lambda=markDuplicatesSpikeIn.dedupLog,
    trim_galore_report=trimGalore.trimLog,
    trim_diversity_report=trimDiversityAdapt.trim_diversity_log,
    phix_report=bowtie2_phix.bowtie2_report,
    mapping_report=chrinfo.report
  }
  
  output {
    trimGalore.trimLog
    trimGalore.trim_summary
    trimDiversityAdapt.r1_diversity_trimmed
    trimDiversityAdapt.r2_diversity_trimmed
    trimDiversityAdapt.trim_diversity_log
    preTrimFastQC.fastQC_report
    postTrimFastQC.fastQC_report
    multiQC.multiQC_report
    alignTrimmedSample.bismark_align_log
    alignTrimmedSample.bismark_report
    alignTrimmedSample.bismark_reads
    quantifyMethylationSample.bismark_summary_report
    alignTrimmedSpikeIn.bismark_align_log
    alignTrimmedSpikeIn.bismark_report
    alignTrimmedSpikeIn.bismark_reads
    quantifyMethylationSpikeIn.bismark_summary_report
    markDuplicatesSample.deduped_bam
    markDuplicatesSample.dedupLog
    markDuplicatesSpikeIn.deduped_bam
    markDuplicatesSpikeIn.dedupLog
    quantifyMethylationSample.CpG_context
    quantifyMethylationSample.CHG_context
    quantifyMethylationSample.CHH_context
    quantifyMethylationSample.M_Bias
    quantifyMethylationSample.bedgraph
    quantifyMethylationSample.bismark_cov
    quantifyMethylationSample.splitting_report
    quantifyMethylationSample.bismark_summary_html
    quantifyMethylationSample.bismark_report_html
    quantifyMethylationSpikeIn.CpG_context
    quantifyMethylationSpikeIn.CHG_context
    quantifyMethylationSpikeIn.CHH_context
    quantifyMethylationSpikeIn.M_Bias
    quantifyMethylationSpikeIn.bedgraph
    quantifyMethylationSpikeIn.bismark_cov
    quantifyMethylationSpikeIn.splitting_report
    quantifyMethylationSpikeIn.bismark_summary_html
    quantifyMethylationSpikeIn.bismark_report_html
    collectQCMetrics.qc_metrics
  }
}

