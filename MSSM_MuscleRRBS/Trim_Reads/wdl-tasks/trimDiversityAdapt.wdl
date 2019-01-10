task trimDiversityAdapt {
  File script # TODO: Create custom docker image with required scripts loaded
  File r1_trimmed
  File r2_trimmed
  String SID
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  command {
    python ${script} -1 ${r1_trimmed} -2 ${r2_trimmed} -d ./
  }
  output {
    File r1_diversity_trimmed = '${SID}_R1_val_1.fq_trimmed.fq.gz'
    File r2_diversity_trimmed = '${SID}_R2_val_2.fq_trimmed.fq.gz'
  }
  runtime {
    # docker image # 99b03a41591c
    docker: "aryeelab/bismark"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }
  meta {
    author: "Samir Akre"
  }
}


workflow trim_diversity_adapters {  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String SID
  call trimDiversityAdapt {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    SID=SID
  }
  output {
    trimDiversityAdapt.r1_diversity_trimmed
    trimDiversityAdapt.r2_diversity_trimmed
  }
}
