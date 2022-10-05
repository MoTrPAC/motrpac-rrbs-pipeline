task markDuplicates{
  File bismark_reads 
  String SID

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker
  command {
    set -ueo pipefail
    mkdir -p dedup/
    cd dedup/
    cp ${bismark_reads} .
    deduplicate_bismark -p --barcode --bam ${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam
    echo "LS"
    ls
  }
  output {
    File umi_tagged_bam = 'dedup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
    File deduped_bam = 'dedup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.bam'
    File dedupLog= 'dedup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplication_report.txt'
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

workflow mark_duplicates{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  call markDuplicates{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker
  }
}
