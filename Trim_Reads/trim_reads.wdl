import "wdl-tasks/trimGalore.wdl" as TG
import "wdl-tasks/trimDiversityAdapt.wdl" as TDA
import "wdl-tasks/fastQC.wdl" as FQC
import "wdl-tasks/multiQC.wdl" as MQC

workflow trim_reads{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  File r1
  File r2
  File trimDiversityScript
  String SID

  ## Runs FastQC pre-trimming 
  call FQC.fastQC as preTrimFastQC {
    input: 
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt, 
    r1=r1,
    r2=r2
  }

  # Trim Galore removes regular adapters
  call TG.trimGalore as trimGalore {input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    r1=r1,
    r2=r2,
    SID=SID
    }

  # NuGen specific diversity adapaters trimmed
  call TDA.trimDiversityAdapt as trimDiversityAdapt {input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    script=trimDiversityScript,
    r1_trimmed=trimGalore.r1_trimmed,
    r2_trimmed=trimGalore.r2_trimmed,
    SID=SID
    }

  # FastQC ran on post trimming reads
  call FQC.fastQC as postTrimFastQC {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt, 
    r1=trimDiversityAdapt.r1_diversity_trimmed,
    r2=trimDiversityAdapt.r2_diversity_trimmed
  }
  call MQC.multiQC as multiQC {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt, 
    fastQCReports=[preTrimFastQC.fastQC_report,postTrimFastQC.fastQC_report]
  }
  output {
    trimGalore.trimLog
    trimGalore.trim_summary
    trimDiversityAdapt.r1_diversity_trimmed
    trimDiversityAdapt.r2_diversity_trimmed
    preTrimFastQC.fastQC_report
    postTrimFastQC.fastQC_report
    multiQC.multiQC_report
  }
}
