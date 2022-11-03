version 1.0

task bowtie2_align {

    input {
        String SID
        File fastqr1
        File fastqr2
        File genome_dir_tar

        Int memory
        Int disk
        Int ncpu
        String docker
    }

    String genome_dir = basename(genome_dir_tar, ".tar.gz")
    String index_prefix = "bowtie2_index"

    parameter_meta {
        SID: {
            type: "id"
        }
        fastqr1: {
            label: "Forward End Read FASTQ File"
        }
        fastqr2: {
            label: "Reverse End Read FASTQ File"
        }
        genome_dir_tar: {
            label: "Bowtie2 Reference Tarball File"
        }
    }

    command <<<
        mkdir genome
        tar -zxvf ~{genome_dir_tar} -C ./genome
        bowtie2 -p ~{ncpu} -1 ~{fastqr1} -2 ~{fastqr2} -x genome/~{genome_dir}/~{index_prefix} --local -S ~{SID}.sam 2> ~{SID}.log
        type=$(echo ${genome_dir}|sed 's/rn_//1')
        tail -n1 ~{SID}.log | awk -v id=~{SID} -v kind=$type '{print "Sample""\t""pct_"kind"\n"id"\t"$1}' > ~{SID}_~{genome_dir}_report.txt
    >>>

    output {
        File bowtie2_output = "{SID}.sam"
        File bowtie2_log = "${SID}.log"
        File bowtie2_report="${SID}_${genome_dir}_report.txt"
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }

    meta {
        author: "Archana Raja"
    }
}

workflow bowtie2_align_workflow {
    call bowtie2_align
}
