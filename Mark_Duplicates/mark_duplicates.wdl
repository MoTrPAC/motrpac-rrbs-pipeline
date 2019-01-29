task markDuplicates{
  File sortedReads
  File sortedReadsIndex
  File stripBismarkScript
  File nudupScript

  String SID
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt

  command {
    samtools view -h ${sortedReads} >${SID}_sorted.sam
    bash ${stripBismarkScript} ${SID}_sorted.sam

    ls
    mkdir tmp
    python2 ${nudupScript} -f ${SID}_I1.fq \
      -T tmp ${SID}_sorted.sam_stripped.sam \
      -o ${SID} \
      >& ${SID}.log
    ls

  }
  output {
    File nudupLog = '${SID}.log'
    File deduped = '${SID}.sorted.dedup.bam'
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

workflow mark_duplicates{
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String SID

  File sortedReads
  File sortedReadsIndex
  call markDuplicates{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    SID=SID,
    sortedReads=sortedReads,
    sortedReadsIndex=sortedReadsIndex
  }
}
