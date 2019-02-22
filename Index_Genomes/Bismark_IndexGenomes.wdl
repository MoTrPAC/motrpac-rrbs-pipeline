task indexGenome {

  File? refAnnotation
  File refGenome
  String genome_dir # Name of folder in which to place bisulfite genome
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker

  # Makes genome directory with input files for use with bismark
  # Runs bismark_genome_preparation
  # Waits for all subprocesses to complete
  # Tars output genome directory with bisulfite conversions
  command {
    mkdir ${genome_dir}
    cd ${genome_dir}
    cp ${refGenome} ./

    if [${refAnnotation} == '']
    then
    echo "No Annotation File"
    else
    echo "Annotation File Found"
    cp ${refAnnotation} ./
    fi

    bismark_genome_preparation .
    cd ..

    FAIL=0
    for job in `jobs -p`
    do
    echo $job
        wait $job || let "FAIL+=1"
    done

    echo $FAIL

    if [ "$FAIL" == "0" ];
    then
    echo "WOO NO JOBS FAILED!"
    else
    echo "($FAIL) Jobs Failed"
    fi

    tar -czvf ${genome_dir}_Bisulfite_Genome.tar.gz ${genome_dir}
    ls
  }
  output {
    File bsGenome = "${genome_dir}_Bisulfite_Genome.tar.gz"
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

workflow Bismark_Index_Generation {
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  String docker
  call indexGenome {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt,
    docker=docker
  }
  output {
    indexGenome.bsGenome
  }
}
