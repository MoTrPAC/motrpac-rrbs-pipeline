version 1.0

task alignTrimmed {
    input {
        File r1_trimmed
        File r2_trimmed
        File genome_dir_tar
        # Name of the genome folder that has been tar balled
        String SID
        Int bismark_multicore
        # Multiply by ~4 to get number of cores required
        #If you increase the multicore to 6 make sure to double up the memory to 80, otherwise you will loose 20-30% of the reads
        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
        String docker
    }

    String genome_dir = basename(genome_dir_tar, ".tar.gz")

    parameter_meta {
        r1_trimmed: {
            label: "Trimmed Forward-End Read FASTQ File"
        }
        r2_trimmed: {
            label: "Trimmed Reverse-End Read FASTQ File"
        }
        genome_dir_tar: {
            label: "Reference Genome Tarball File"
        }
        SID: {
            type: "id"
        }
        bismark_multicore: {
            label: "Number of cores to use for bismark"
        }
    }

    # Assumes reference genome with bisulfite conversion reference is a tar file,
    #  genome_dir is the name of the directory that was tar balled
    command <<<
        set -ueo pipefail
        mkdir genome
        mkdir tmp
        tar -zxvf ~{genome_dir_tar} -C ./genome

        echo "Running: ls"
        ls
        echo "--- End ls ---"

        echo "Running: bismark"
        bismark genome/~{genome_dir} --multicore ~{bismark_multicore} \
        -1 ~{r1_trimmed} \
        -2 ~{r2_trimmed} \
        >& ~{SID}_bismarkAlign.log
        echo "--- End bismark ---"

        echo "Running: ls"
        ls
        echo "--- End ls ---"
        sam=~{SID}.sam

        #Fix inconsistencies while using different multticore setting by sorting sam by mapping quality and then by read name
        echo "Runnning Samtools"
        samtools view -@ ~{num_threads} -H ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam >$sam
        samtools view -@ ~{num_threads} ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam |sort -k5,5nr -k1,1 -s -S~{memory}G  >>$sam
        echo "Finished sorting"
        samtools view -@ ~{num_threads} -b $sam -o ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam
        echo "Finished running samtools"
    >>>

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

workflow align_trimmed {
    input {
        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
        String docker

        String SID
    }

    call alignTrimmed {
        input:
            memory=memory,
            disk_space=disk_space,
            num_threads=num_threads,
            num_preempt=num_preempt,
            docker=docker,
            SID=SID
    }

    output {
        File bismark_align_log = alignTrimmed.bismark_align_log
        File bismark_report = alignTrimmed.bismark_report
        File bismark_reads = alignTrimmed.bismark_reads
    }
}
