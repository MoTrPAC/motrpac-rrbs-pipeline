task tag_udup{
  File bismark_reads 
  String SID

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    set -ueo pipefail
    mkdir -p mark_udup/
    cd mark_udup/
    cp ${bismark_reads} .
    bash /src/bismark_bam_UMI_format.sh ${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam
    echo "LS"
    ls
  }
  output {
    File umi_dup_marked = 'mark_udup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
  }
  runtime {
    docker: "${docker}"
    memory: "${memory}GB"
    disks: "local-disk ${disk_space} HDD"
    cpu: "${num_threads}"
    preemptible: "${num_preempt}"
  }
  meta {
    author: "Archana Raja"
  }
}

workflow mark_udup{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  call tag_udup{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker
  }
}
