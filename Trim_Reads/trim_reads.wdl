import "wdl-tasks/trimGalore.wdl" as TG
import "wdl-tasks/trimDiversityAdapt.wdl" as TDA

workflow trim_reads{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  File r1
  File r2
  File trimDiversityScript
  String SID

  call TG.trimGalore as trimGalore {input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    r1=r1,
    r2=r2,
    SID=SID
    }

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


  output {
    trimGalore.trimLog
    trimGalore.trim_summary
    trimDiversityAdapt.r1_diversity_trimmed
    trimDiversityAdapt.r2_diversity_trimmed
  }
}
