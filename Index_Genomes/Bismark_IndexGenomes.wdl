task indexGenome {

  String subjectType
  File annotation
  File genome
  File lambdaGenome
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt

  command {
    mkdir genomes
    cd genomes
    cp ${genome} ./
    cp ${annotation} ./
    cp ${lambdaGenome} ./
    bismark_genome_preparation .
    tar -cvf Bisulfite_Genome.tar ./Bisulfite_Genome 
  }
  output {
    File bsGenome = "genomes/Bisulfite_Genome.tar"
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
  File humanAnnotation
  File humanGenome
  File ratAnnotation
  File ratGenome
  File lambdaGenome
  Int memory
  Int disk_space
  Int num_threads
  Int num_preempt
  call indexGenome as humanIndex {
    input: subjectType="human",
    annotation=humanAnnotation,
    genome=humanGenome,
    lambdaGenome=lambdaGenome,
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt
  }
  call indexGenome as ratIndex {
    input: subjectType="rat",
    annotation=ratAnnotation,
    genome=ratGenome,
    lambdaGenome=lambdaGenome,
    memory=memory,
    disk_space=disk_space,
    num_threads=num_threads,
    num_preempt=num_preempt
  }
  output {
    humanIndex.bsGenome
    ratIndex.bsGenome
  }
}
