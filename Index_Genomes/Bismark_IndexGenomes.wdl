task indexGenome {

  File refAnnotation
  File refGenome
  File lambdaGenome
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt

  # Makes genome directory with input files for use with bismark
  # Runs bismark_genome_preparation
  # Waits for all subprocesses to complete
  # Tars output genome directory with bisulfite conversions
  command {
    mkdir genomes
    cd genomes
    cp ${refGenome} ./
    cp ${refAnnotation} ./
    cp ${lambdaGenome} ./
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

    tar -cvf Bisulfite_Indexed_Genome.tar ./genomes
  }
  output {
    File bsGenome = "Bisulfite_Indexed_Genome.tar"
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

workflow Bismark_Index_Generation {
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  call indexGenome {
    input:
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt
  }
  output {
    indexGenome.bsGenome
  }
}
