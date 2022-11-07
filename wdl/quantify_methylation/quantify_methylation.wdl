version 1.0

task quantifyMethylation {
    input {
        File bismark_umi_marked_reads
        File bismark_deduplicated_reads
        File bismark_alignment_report
        File bismark_dedup_report
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
        bismark_umi_marked_reads: {
            label: "Bismark UMI-Marked BAM File"
        }
        bismark_deduplicated_reads: {
            label: "Bismark De-duplicated BAM File"
        }
        bismark_alignment_report: {
            label: "Bismark Alignment Report"
        }
        bismark_dedup_report: {
            label: "Bismark De-duplication Report"
        }
    }

    command <<<
        set -ueo pipefail
        cp ~{bismark_umi_marked_reads} ./
        cp ~{bismark_deduplicated_reads} ./
        cp ~{bismark_alignment_report} ./
        cp ~{bismark_dedup_report} ./
        echo "LS"
        ls

        echo "--- Running: bismark_methylation_extractor ---"
        bismark_methylation_extractor ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.bam \
            --multicore ~{ncpu} \
            --comprehensive \
            --bedgraph
        echo "--- Finished: bismark_methylation_extractor ---"

        echo "------ Running : bismark2summary-------"
        bismark2summary
        echo "---- Finished running bismark2summary------"

        echo "--- Running: bismark2report ---"
        bismark2report -o ~{SID}.html  -a ~{SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt
        echo "--- Finished: bismark2report ---"
    >>>

    output {
        File CpG_context="CpG_context_${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.txt"
        File CHG_context="CHG_context_${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.txt"
        File CHH_context="CHH_context_${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.txt"
        File M_Bias="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.M-bias.txt"
        File bedgraph="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.bedGraph.gz"
        File bismark_cov="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated.bismark.cov.gz"
        File splitting_report="${SID}_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplicated_splitting_report.txt"
        File bismark_summary_report = "bismark_summary_report.txt"
        File bismark_summary_html = "bismark_summary_report.html"
        File bismark_report_html = "${SID}.html"

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

workflow quantify_methylation {
    input {
        String SID
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    call quantifyMethylation {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu,
            docker=docker,
            SID=SID
    }
    output {
        File CpG_context=quantifyMethylation.CpG_context
        File CHG_context=quantifyMethylation.CHG_context
        File CHH_context=quantifyMethylation.CHH_context
        File M_Bias=quantifyMethylation.M_Bias
        File bedgraph=quantifyMethylation.bedgraph
        File bismark_cov=quantifyMethylation.bismark_cov
        File splitting_report=quantifyMethylation.splitting_report
        File bismark_summary_report =quantifyMethylation.bismark_summary_report
        File bismark_summary_html =quantifyMethylation.bismark_summary_html
        File bismark_report_html =quantifyMethylation.bismark_report_html
    }
}
