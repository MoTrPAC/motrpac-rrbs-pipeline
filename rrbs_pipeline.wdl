import "Trim_Reads/wdl-tasks/trimGalore.wdl" as TG
import "Trim_Reads/wdl-tasks/trimDiversityAdapt.wdl" as TDA
import "Trim_Reads/wdl-tasks/fastQC.wdl" as FQC
import "Trim_Reads/wdl-tasks/multiQC.wdl" as MQC
import "Trim_Reads/wdl-tasks/attachUMI.wdl" as AUMI
import "Align_Trimmed/align_trimmed.wdl" as AT
import "Mark_Duplicates/mark_duplicates.wdl" as MD
import "Quantify_Methylation/quantify_methylation.wdl" as QM

workflow rrbs_pipeline{
  # Default values for runtime, changed in individual calls according to requirements
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

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
    fastQCReports=[preTrimFastQC.fastQC_report,postTrimFastQC.fastQC_report]
  }

  # Align trimmed reads to species of interest
  call AT.alignTrimmed as alignTrimmedSample{
    # NOT PREEMPTIBLE INSTANCE
    input:
    memory=50,
    disk_space=100,
    num_threads=16,
    num_preempt=0,
    docker=docker,
    SID=SID,
    bismark_multicore=4,
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
    disk_space=100,
    num_threads=16,
    num_preempt=0,
    docker=docker,
    SID=SID,
    bismark_multicore=4,
    r1_trimmed=trimDiversityAdapt.r1_diversity_trimmed,
    r2_trimmed=trimDiversityAdapt.r2_diversity_trimmed,
    genome_dir=spike_in_genome_dir,
    genome_dir_tar=spike_in_genome_tar
  }

  # Remove PCR Duplicates from sample
  call MD.markDuplicates as markDuplicatesSample {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt,
    docker=docker,
    SID=SID,
    bismarkReads=alignTrimmedSample.bismark_reads
    } 

  # Remove PCR Duplicates from Lambda phage spike in
  call MD.markDuplicates as markDuplicatesSpikeIn{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=1,
    num_preempt=num_preempt,
    docker=docker,
    SID=SID,
    bismarkReads=alignTrimmedSpikeIn.bismark_reads
    } 

  # Quantify Methylation for sample
  call QM.quantifyMethylation as quantifyMethylationSample {
    input:
    memory=60,
    disk_space=60,
    num_threads=16,
    num_preempt=num_preempt,
    docker=docker,
    bismark_deduplicated_reads=markDuplicatesSample.deduped,
    SID=SID
    }

  # Quantify Methylation for Lambda control spike in
  call QM.quantifyMethylation as quantifyMethylationSpikeIn{
    input:
    memory=60,
    disk_space=60,
    num_threads=16,
    num_preempt=num_preempt,
    docker=docker,
    bismark_deduplicated_reads=markDuplicatesSpikeIn.deduped,
    SID=SID
    }

  output {
    trimGalore.trimLog
    trimGalore.trim_summary
    trimDiversityAdapt.r1_diversity_trimmed
    trimDiversityAdapt.r2_diversity_trimmed
    preTrimFastQC.fastQC_report
    postTrimFastQC.fastQC_report
    multiQC.multiQC_report
    alignTrimmedSample.bismark_align_log
    alignTrimmedSample.bismark_report
    alignTrimmedSample.bismark_reads
    alignTrimmedSample.bismark_summary
    alignTrimmedSpikeIn.bismark_align_log
    alignTrimmedSpikeIn.bismark_report
    alignTrimmedSpikeIn.bismark_reads
    alignTrimmedSpikeIn.bismark_summary
    markDuplicatesSample.deduped
    markDuplicatesSpikeIn.deduped
    quantifyMethylationSample.CpG_context
    quantifyMethylationSample.CHG_context
    quantifyMethylationSample.CHH_context
    quantifyMethylationSample.M_Bias
    quantifyMethylationSample.bedgraph
    quantifyMethylationSample.bismark_cov
    quantifyMethylationSample.splitting_report
    quantifyMethylationSpikeIn.CpG_context
    quantifyMethylationSpikeIn.CHG_context
    quantifyMethylationSpikeIn.CHH_context
    quantifyMethylationSpikeIn.M_Bias
    quantifyMethylationSpikeIn.bedgraph
    quantifyMethylationSpikeIn.bismark_cov
    quantifyMethylationSpikeIn.splitting_report
  }
}
