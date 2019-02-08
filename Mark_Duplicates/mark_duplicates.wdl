task markDuplicates{
  File bismarkReads 
  String SID

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  command {
    bash /src/bismark_bam_UMI_format.sh ${bismarkReads}
    deduplicate_bismark -p --barcode --bam ${bismarkReads}
    echo "LS"
    ls

  }
  output {
    File deduped = '${bismarkReads}'
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
