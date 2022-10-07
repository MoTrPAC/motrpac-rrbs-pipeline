version 1.0

task samtools_mapped {

    input {
        File input_bam
        String SID

        Int memory
        Int disk_space
        Int num_threads
        Int num_preempt
        String docker
    }

    parameter_meta {
        SID: {
            type: "id"
        }
        input_bam: {
            label: "Aligned BAM File"
        }
    }

    command <<<
        set -euo pipefail
        samtools view ~{input_bam}|cut -f 3|sort |uniq -c > ~{SID}_chr_info.txt
        Total=$(awk '{sum+=$1}END{print sum}' ~{SID}_chr_info.txt)
        grep "chrX" ~{SID}_chr_info.txt|awk -v tot=$Total  -v name=~{SID} '{print "Sample""\t""pct_chrX""\n"name"\t"($1/tot)*100}' >chrX.txt
        grep "chrY" ~{SID}_chr_info.txt|awk -v tot=$Total '{print "pct_chrY""\n"($1/tot)*100}' >chrY.txt
        grep "chrM" ~{SID}_chr_info.txt|awk -v tot=$Total '{print "pct_chrM""\n"($1/tot)*100}' >chrM.txt
        grep "chr" ~{SID}_chr_info.txt|grep -v "chrX\|chrY\|chrM" |awk -v tot=$Total '{sum+=$1}END{print "pct_chrAuto""\n"(sum/tot)*100}' >chrAuto.txt
        grep -v "chr" ~{SID}_chr_info.txt|awk -v tot=$Total '{sum+=$1}END{print "pct_contig""\n"(sum/tot)*100}' >contig.txt
        paste chrX.txt chrY.txt chrM.txt chrAuto.txt contig.txt >~{SID}_mapped_report.txt
    >>>

    output {
        File aligned_chrinfo = "${SID}_chr_info.txt"
        File report = "${SID}_mapped_report.txt"
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk_space} HDD"
        cpu: "${num_threads}"
        preemptible: "${num_preempt}"
    }

    meta {
        author: "Archana Raja"
    }
}


workflow mapped_workflow {
    call samtools_mapped
}
