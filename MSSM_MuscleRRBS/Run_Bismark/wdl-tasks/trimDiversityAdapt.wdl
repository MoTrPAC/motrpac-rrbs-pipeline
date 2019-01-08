task trimDiversityAdapt {
  File script # TODO: Create custom docker image with required scripts loaded
  File r1_trimmed
  File r2_trimmed

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  command {
    python ${script} -1 ${r1_trimmed} -2 ${r2_trimmed}
    ls
  }
  output {
    Array[File] outFiles = glob('*')
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
  call trimDiversityAdapt {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt
  }
  output {
    trimDiversityAdapt.outFiles
  }
}
