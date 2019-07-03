task alignTrimmed{
  File r1_trimmed
  File r2_trimmed
  File genome_dir_tar
  String genome_dir # Name of the genome folder that has been tar balled 
  String SID
  Int bismark_multicore = 1 # Multiply by ~4 to get number of cores required

  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  # Assumes reference genome with bisulfite conversion reference is a tar file,
  #  genome_dir is the name of the directory that was tar balled
  command {
    set -ueo pipefail
    mkdir genome
    mkdir tmp
    tar -zxvf ${genome_dir_tar} -C ./genome

    echo "Running: ls"
    ls
    echo "--- End ls ---"

    echo "Running: bismark"
    bismark genome/${genome_dir} --multicore ${bismark_multicore} \
    -1 ${r1_trimmed} \
    -2 ${r2_trimmed} \
    >& ${SID}_bismarkAlign.log
    echo "--- End bismark ---"

    echo "Running: ls"
    ls
    echo "--- End ls ---"
  
  }
  output {
    File bismark_align_log = '${SID}_bismarkAlign.log'
    File bismark_report = '${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt'
    File bismark_reads = '${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
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


workflow align_trimmed{  
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  String SID
  call alignTrimmed{
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker,
    SID=SID
  }
  output {
    alignTrimmed.bismark_align_log
    alignTrimmed.bismark_report
    alignTrimmed.bismark_reads
  }
}
