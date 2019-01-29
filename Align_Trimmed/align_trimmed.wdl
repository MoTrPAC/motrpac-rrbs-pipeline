task alignTrimmed{
  File r1_trimmed
  File r2_trimmed
  File genome_dir_tar
  String genome_dir # Name of the genome folder that has been tar balled 
  String SID
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt

  # Assumes reference genome with bisulfite conversion reference is a tar file,
  #  genome_dir is the name of the directory that was tar balled
  command {
    mkdir genome
    mkdir tmp
    tar -zxvf ${genome_dir_tar} -C ./genome
    bismark genome/${genome_dir} --multicore ${num_threads}\
      -1 ${r1_trimmed} \
      -2 ${r2_trimmed} \
      >& ${SID}_bismarkAlign.log
    
    samtools sort *.bam \
    -m 2G \
    -T tmp \
    -o ${SID}_sorted.bam
    -@ ${num_threads}

    samtools index ${SID}_sorted.bam
  }
  output {
    File bismarkAlignLog = '${SID}_bismarkAlign.log'
    File sortedReads = '${SID}_sorted.bam'
    File sortedReadsIndex = '${SID}_sorted.bam.bai'
    # TODO: Add output files of alignment
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


workflow align_trimmed{  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String SID
  call alignTrimmed{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    SID=SID
  }
  output {
    #TODO: Add bismark alignment and samtools ouput to outputs
    alignTrimmed.bismarkAlignLog
  }
}
