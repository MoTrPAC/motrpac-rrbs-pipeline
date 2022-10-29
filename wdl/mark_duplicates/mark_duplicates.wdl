version 1.0

task markDuplicates {
    input {
        File bismark_reads
        String SID

        Int memory
        Int disk
        Int ncpu
        String docker
    }

    parameter_meta {
        SID: {
            type: "id"
        }
        bismark_reads: {
            label: "Bismark Reads BAM File"
        }
    }

    command <<<
        set -ueo pipefail
        mkdir -p dedup/
        cd dedup/
        cp ~{bismark_reads} .
        deduplicate_bismark -p --barcode --bam ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam
        echo "LS"
        ls
    >>>

    output {
        File umi_tagged_bam = 'dedup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.bam'
        File deduped_bam = 'dedup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.bam'
        File dedupLog= 'dedup/${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplication_report.txt'
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

workflow mark_duplicates {
    input {
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    call markDuplicates {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker
    }
}
