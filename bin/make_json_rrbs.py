"""Usage: python bin/make_json_rrbs.py [comma separated sample list]
path_to_output_json Usage: python bin/make_json_rrbs.py \
/Users/archanaraja/work/repo/motrpac-rrbs-pipeline/sample_list/pilot_list1,
/Users/archanaraja/work/repo/motrpac-rrbs-pipeline/sample_list/pilot_list2
/Users/archanaraja/work/repo/motrpac-rrbs-pipeline/sample_list/
"""
import json
import os
import argparse
from typing import List


def main(filelist: List[str], output_path: str) -> None:
    for i in filelist:
        base_filename = os.path.basename(i)
        outfile = os.path.join(output_path, base_filename + "_rrbs.json")
        print(outfile)
        # f=open(i+"_rrbs.json","w")
        f = open(outfile, "w")
        #  print(f)
        #  print(os.getcwd())
        r1 = [line.strip("\n") for line in open(i)]
        r2 = [line.strip("\n").replace("_R1.fastq", "_R2.fastq") for line in open(i)]
        i1 = [line.strip("\n").replace("_R1.fastq", "_I1.fastq") for line in open(i)]
        prefix = [
            line.strip("\n").split("/")[-1].split("_R1.fastq.gz")[0] for line in open(i)
        ]
        d = {
            "rrbs_pipeline.r1": r1,
            "rrbs_pipeline.r2": r2,
            "rrbs_pipeline.i1": i1,
            "rrbs_pipeline.sample_prefix": prefix,
            "rrbs_pipeline.sample_genome_dir_tar": "gs://rna-seq_araja/rrbs/genomes/rat/rat_Bisulfite_Genome.tar.gz",
            "rrbs_pipeline.phix_genome_dir_tar": "gs://rna-seq_araja/references/rn/bowtie2_index/phix.tar.gz",
            "rrbs_pipeline.spike_in_genome_dir_tar": "gs://rna-seq_araja/rrbs/genomes/lambda/lambda_Bisulfite_Genome.tar.gz",
            "rrbs_pipeline.docker": "gcr.io/motrpac-portal/motrpac_rrbs:araja_08_05_2019",
            "rrbs_pipeline.output_report_name": "String",
            "rrbs_pipeline.bismark_docker": "gcr.io/motrpac-portal/bismark:0.20.0",
            "rrbs_pipeline.align_trim_sample_disk": 200,
            "rrbs_pipeline.align_trim_sample_ncpu": 12,
            "rrbs_pipeline.align_trim_sample_ramGB": 40,
            "rrbs_pipeline.align_trim_spike_in_disk": 200,
            "rrbs_pipeline.align_trim_spike_in_ncpu": 12,
            "rrbs_pipeline.align_trim_spike_in_ramGB": 40,
            "rrbs_pipeline.attach_umi_disk": 150,
            "rrbs_pipeline.attach_umi_ncpu": 8,
            "rrbs_pipeline.attach_umi_ramGB": 40,
            "rrbs_pipeline.bowtie2_phix_disk": 200,
            "rrbs_pipeline.bowtie2_phix_ncpu": 10,
            "rrbs_pipeline.bowtie2_phix_ramGB": 40,
            "rrbs_pipeline.chrinfo_disk": 200,
            "rrbs_pipeline.chrinfo_ncpu": 8,
            "rrbs_pipeline.chrinfo_ramGB": 32,
            "rrbs_pipeline.collect_qc_disk": 50,
            "rrbs_pipeline.collect_qc_ncpu": 4,
            "rrbs_pipeline.collect_qc_ramGB": 20,
            "rrbs_pipeline.mark_dup_sample_disk": 200,
            "rrbs_pipeline.mark_dup_sample_ncpu": 1,
            "rrbs_pipeline.mark_dup_sample_ramGB": 32,
            "rrbs_pipeline.mark_dup_spike_in_disk": 200,
            "rrbs_pipeline.mark_dup_spike_in_ncpu": 1,
            "rrbs_pipeline.mark_dup_spike_in_ramGB": 32,
            "rrbs_pipeline.merge_results_disk": 10,
            "rrbs_pipeline.merge_results_ncpu": 2,
            "rrbs_pipeline.merge_results_ramGB": 8,
            "rrbs_pipeline.multiqc_disk": 150,
            "rrbs_pipeline.multiqc_ncpu": 1,
            "rrbs_pipeline.multiqc_ramGB": 40,
            "rrbs_pipeline.posttrim_fastqc_disk": 150,
            "rrbs_pipeline.posttrim_fastqc_ncpu": 1,
            "rrbs_pipeline.posttrim_fastqc_ramGB": 40,
            "rrbs_pipeline.pretrim_fastqc_disk": 150,
            "rrbs_pipeline.pretrim_fastqc_ncpu": 1,
            "rrbs_pipeline.pretrim_fastqc_ramGB": 40,
            "rrbs_pipeline.quant_methyl_sample_disk": 200,
            "rrbs_pipeline.quant_methyl_sample_ncpu": 16,
            "rrbs_pipeline.quant_methyl_sample_ramGB": 60,
            "rrbs_pipeline.quant_methyl_spike_in_disk": 200,
            "rrbs_pipeline.quant_methyl_spike_in_ncpu": 16,
            "rrbs_pipeline.quant_methyl_spike_in_ramGB": 60,
            "rrbs_pipeline.tag_udup_sample_disk": 150,
            "rrbs_pipeline.tag_udup_sample_ncpu": 6,
            "rrbs_pipeline.tag_udup_sample_ramGB": 40,
            "rrbs_pipeline.tag_udup_spike_in_disk": 150,
            "rrbs_pipeline.tag_udup_spike_in_ncpu": 6,
            "rrbs_pipeline.tag_udup_spike_in_ramGB": 40,
            "rrbs_pipeline.trim_diversity_adapt_disk": 150,
            "rrbs_pipeline.trim_diversity_adapt_ncpu": 1,
            "rrbs_pipeline.trim_diversity_adapt_ramGB": 40,
            "rrbs_pipeline.trim_reg_adapt_disk": 150,
            "rrbs_pipeline.trim_reg_adapt_ncpu": 1,
            "rrbs_pipeline.trim_reg_adapt_ramGB": 40,
        }

        json.dump(d, f)
        f.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create a JSON file for the RRBS pipeline"
    )
    parser.add_argument("--filelist", help="File list to process")
    parser.add_argument("--output", help="Output path basename")
    args = parser.parse_args()

    main(args.filelist.split(","), args.output)
