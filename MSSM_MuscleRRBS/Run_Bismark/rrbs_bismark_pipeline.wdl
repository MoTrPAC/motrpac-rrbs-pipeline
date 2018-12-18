import "wdl-tasks/trimGalore.wdl" as trimGalore
import "wdl-tasks/trimDiversityAdapt.wdl" as trimDiversityAdapt

workflow rrbs_bismark_pipeline{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  call trimGalore {input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt}
  output {
    trimGalore.trimLog
    trimGalore.r1_trimmed
    trimGalore.r2_trimmed
    trimGalore.trim_summary
  }
}

