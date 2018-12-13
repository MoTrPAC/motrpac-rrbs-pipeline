task loadDependencies {
  command {
    bismark
  }
  output {
    File outMessage = stdout()
  }
}

workflow testDependencies {
  command {
    source activate rrbs_bismark
  }
  call loadDependencies
  output {
    File message = loadDependencies.outMessage
  }
}
