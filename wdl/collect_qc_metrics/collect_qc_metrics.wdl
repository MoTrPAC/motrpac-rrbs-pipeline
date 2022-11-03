version 1.0

task collectQCMetrics {
    input {
        File lambda_bismark_summary_report
        File species_bismark_summary_report
        File bismark_bt2_pe_report
        File multiQC_report
        File trim_galore_report
        File trim_diversity_report
        File phix_report
        File mapping_report
        String SID

        # Runtime Attributes
        Int memory
        Int disk
        Int ncpu
        String docker
    }

    parameter_meta {
        SID: {
            type: "id"
        }
        lambda_bismark_summary_report: {
            label: "Spike In Methylation Summary Report"
        }
        species_bismark_summary_report: {
            label: "Sample Methylation Summary Report"
        }
        bismark_bt2_pe_report: {
            label: "Aligned Sample Bismark Summary Report"
        }
        species_bismark_summary_report: {
            label: "Trimmed/Aligned Sample Summary Report"
        }
        multiQC_report: {
            label: "MultiQC Report"
        }
        trim_galore_report: {
            label: "Regular Adapter Trimming Report"
        }
        trim_diversity_report: {
            label: "NuGen-specific Adapter Trimming Report"
        }
        phix_report: {
            label: "Bowtie2 Phix Mapping Report"
        }
        mapping_report: {
            label: "Chromosomal/Contig Mapping Report"
        }
    }

    command {
        set -ueo pipefail

        tar -xzvf ~{multiQC_report}
        ls

        /usr/bin/python3 /src/collect_qc_metrics.py \
            --summary ~{species_bismark_summary_report} \
            --lambda_summary ~{lambda_bismark_summary_report} \
            --bt2 ~{bismark_bt2_pe_report} \
            --multiqc multiQC_report/multiqc_data/multiqc_general_stats.txt \
            --tg ~{trim_galore_report} \
            --td ~{trim_diversity_report} \
            --phix_report ~{phix_report} \
            --mapped_report ~{mapping_report}
    }

    output {
        File qc_metrics = '${SID}_qcmetrics.csv'
    }

    runtime {
        docker: "${docker}"
        memory: "${memory}GB"
        disks: "local-disk ${disk} HDD"
        cpu: "${ncpu}"
    }

    meta {
        author: "Samir Akre,Archana Raja"
    }
}

workflow collect_qc_metrics {
    input {
        Int memory
        Int disk
        Int ncpu
    }

    call collectQCMetrics {
        input:
            memory=memory,
            disk=disk,
            ncpu=ncpu
    }
}
