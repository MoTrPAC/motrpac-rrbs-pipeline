task quantifyMethylation{
  File bismarkDeduplicatedReads 

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    echo "Running: bismark_methylation_extractor"
    bismark_methylation_extractor ${bismarkDeduplicatedReads} \
    --multicore ${num_threads}\
    --comprehensive \
    --bedgraph 
    echo "Finished: bismark_methylation_extractor"

    echo "Running: ls"
    ls
    echo "Finished: ls"

  }
  output {
    File CpG_context="CpG_context*.fastq_bismark.txt"
    File CHG_context="CHG_context*.fastq_bismark.txt"
    File CHH_context="CHH_context*.fastq_bismark.txt"
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

workflow quantify_methylation{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  call quantifyMethylation{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker
  }
  output {
    quantifyMethylation.CpG_context
    quantifyMethylation.CHG_context
    quantifyMethylation.CHH_context
  }
}
