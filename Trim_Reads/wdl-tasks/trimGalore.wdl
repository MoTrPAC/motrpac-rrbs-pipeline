task trimGalore {
  File r1
  File r2
  String SID

  # Runtime Attributes
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    set -ueo pipefail
    trim_galore --paired \
      --adapter AGATCGGAAGAGC \
      --adapter2 AAATCAAAAAAAC \
      --length 20 ${r1} ${r2} \
      --fastqc_args "-o fastqc" \
      >& ${SID}_trim.log
    ls
  }
  output {
    File trimLog = "${SID}_trim.log"
    File r1_trimmed = "${SID}_attached_R1_val_1.fq.gz"
    File r2_trimmed = "${SID}_attached_R2_val_2.fq.gz"
    Array[File] trim_summary = glob("*trimming_report.txt")
  }
  runtime {
    docker: "${docker}"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }
  meta {
    author: "Samir Akre"
  }
}

workflow trim_galore{  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  call trimGalore{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt
  }
  output {
    trimGalore.trimLog
    trimGalore.r1_trimmed
    trimGalore.r2_trimmed
    trimGalore.trim_summary
  }
}
