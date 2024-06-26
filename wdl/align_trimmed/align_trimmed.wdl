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
        Int disk
        Int ncpu
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
            type: "runtime",
            label: "Number of cores to use for bismark"
        }
    }

    # Assumes reference genome with bisulfite conversion reference is a tar file,
    #  genome_dir is the name of the directory that was tar balled
    command <<<
        set -ueo pipefail
        echo "--- $(date "+[%b %d %H:%M:%S]") Beginning task, making output directories ---"
        mkdir -p genome/~{genome_dir}
        mkdir tmp

        echo "--- $(date "+[%b %d %H:%M:%S]") Extracting genome tarball into ./genome/~{genome_dir} ---"
        tar -zxvf ~{genome_dir_tar} -C ./genome/~{genome_dir} --strip-components 1

        echo "--- $(date "+[%b %d %H:%M:%S]") Listing folder ---"
        ls

        echo "--- $(date "+[%b %d %H:%M:%S]") Running bismark ---"
        bismark genome/~{genome_dir} --multicore ~{bismark_multicore} \
            -1 ~{r1_trimmed} \
            -2 ~{r2_trimmed} \
            >& ~{SID}_bismarkAlign.log
            echo "--- End bismark ---"

        echo "--- $(date "+[%b %d %H:%M:%S]") Listing folder ---"
        ls

        sam=~{SID}.sam
        #Fix inconsistencies while using different multticore setting by sorting sam by mapping quality and then by read name

        echo "--- $(date "+[%b %d %H:%M:%S]") Running samtools ---"
        samtools view -@ ~{ncpu} -H ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam >$sam
        samtools view -@ ~{ncpu} ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam |sort -k5,5nr -k1,1 -s -S~{memory}G  >>$sam

        echo "--- $(date "+[%b %d %H:%M:%S]") Finished sorting ---"
        samtools view -@ ~{ncpu} -b $sam -o ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam

        echo "--- $(date "+[%b %d %H:%M:%S]") Finished task ---"
    >>>

    output {
        File bismark_align_log = '${SID}_bismarkAlign.log'
        File bismark_report = '${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt'
        File bismark_reads = '${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }

    meta {
        author: "Samir Akre"
    }
}

workflow align_trimmed {
    input {
        Int memory
        Int disk
        Int ncpu
        String docker

        String SID
    }

    call alignTrimmed {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            SID=SID
    }

    output {
        File bismark_align_log = alignTrimmed.bismark_align_log
        File bismark_report = alignTrimmed.bismark_report
        File bismark_reads = alignTrimmed.bismark_reads
    }
}

