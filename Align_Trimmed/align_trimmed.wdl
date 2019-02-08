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

    echo "Running: bismark"
    bismark genome/${genome_dir} --multicore ${num_threads} \
    -1 ${r1_trimmed} \
    -2 ${r2_trimmed} \
    >& ${SID}_bismarkAlign.log
  }
  output {
    File bismarkAlignLog = '${SID}_bismarkAlign.log'
    File bismarkReport = '${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt'
    File bismarkReads = '${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
  }
  runtime {
    docker: "akre96/motrpac_rrbs:v0.1"
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
    alignTrimmed.bismarkReport
    alignTrimmed.bismarkReads
  }
}
