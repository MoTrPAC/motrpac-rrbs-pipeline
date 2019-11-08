# Authors: Samir Akre Archana Raja
# Purpose: 
#   The goal of this script is to agregate QC metrics for the motrpac RRBS initial processing pipeline. Read the usage() function for details on usage.
# Output:
#   writes csv file: '${SID}_qcmetrics.csv' where ${SID} is based on the sample ID sent as input with -u or --sid
#Usage :  python3 collect_qc_metrics.py --summary reports/bismark_summary_report.txt --bt2 reports/Rat_Muscle_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt  --lambda_summary reports/lambda/bismark_summary_report.txt --multiqc  reports/multiQC_report/multiqc_data/multiqc_general_stats.txt --tg reports/Rat_Muscle_trim.log --td reports/Rat_Muscle_trimDiversityAdapt.log --phix_report reports/Rat_Muscle_phix_report.txt --mapped_report reports/Rat_Muscle_mapped_report.txt
#Notes : Any of the function can throw an error on the script like a variable is used before it's being declared , if the report it reads is empty , have to add a check to throw exceptions on empty file.
import argparse
import csv
import re
import pandas as pd
from statistics import mean
import os

def parseTrimGaloreLog(tglog):
     l=[]
     data={}
     with open(tglog) as trim_log:        
        for line in trim_log:
            if "Reads with adapters:" in line :
                l.append(float(re.split('\(|\%|\)',line)[1]))
     pct_adapter_detected = round(mean(l),3)
     data['pct_adapter_detected'] = [pct_adapter_detected]
     return pd.DataFrame(data=data)

def parseTrimDiversityLog(tdlog):
     l=[]
     data={}
     with open(tdlog) as trim_log:
      for line in trim_log:
          if "Fwd:  D0:" in line :
             l=re.split('other=|total=|\(|\)',line)
             other = int(l[-4])
             total = int(l[-2])
             pct_no_MSPI = round((other/total)*100,3)
     data['pct_no_MSPI'] = [pct_no_MSPI]
     return pd.DataFrame(data=data) , total

             
# Parse bismark_summary_report.txt file for RRBS QC metrics
# input String {bismarkSummary} path to file containing output from bismark2summary ran on alignment
def parseBismarkSummary(bismarkSummary):
    report_table = pd.read_csv(bismarkSummary, delimiter='\t')
    # for col in report_table.columns:
    #    print(col, ': ', report_table[col].values[0])
    data = {}
    unMetCs = report_table['Unmethylated CpGs'] + report_table['Unmethylated chgs'] + report_table['Unmethylated CHHs']
    eff = unMetCs / report_table['Total Cs']
    data['pct_Uniq'] = (report_table['Aligned Reads']/report_table['Total Reads'])*100
    data['Aligned Reads'] = report_table['Aligned Reads']
    data['pct_Aligned'] = [100*(report_table['Aligned Reads'] / report_table['Total Reads']).values[0]]
    data['pct_Unaligned'] = [100*(report_table['Unaligned Reads'] / report_table['Total Reads']).values[0]]
    data['pct_Ambi'] = [100*(report_table['Ambiguously Aligned Reads'] / report_table['Total Reads']).values[0]]
    data['pct_CpG'] = [100*(report_table['Methylated CpGs'] / (report_table['Unmethylated CpGs'] + report_table['Methylated CpGs'])).values[0]]
    data['pct_CHG'] = [100*(report_table['Methylated chgs'] / (report_table['Unmethylated chgs'] + report_table['Methylated chgs'])).values[0]]
    data['pct_CHH'] = [100*(report_table['Methylated CHHs'] / (report_table['Unmethylated CHHs'] + report_table['Methylated CHHs'])).values[0]]
    data['pct_umi_dup'] = [100*(report_table['Duplicate Reads (removed)'] / report_table['Aligned Reads']).values[0]] 
    return pd.DataFrame(data=data)

# Parse information related to the 4 types of strands in RRBS data.
# input String {bismarkReport} path to file containing bismark_bt2_PE_report.txt style output 
def get4StrandMapData(bismarkReport):
    data = {}
    with open(bismarkReport, 'r') as report:
        for line in report:
            ot = re.search(r"CT\/GA\/CT:\s(\d+)\s", line)
            if ot:
                # print('num OT: ', ot.group(1))
                data['pct_OT'] = [float(ot.group(1))]
            ctot = re.search(r"GA\/CT\/CT:\s(\d+)\s", line)
            if ctot:
                # print('num CTOT: ', ctot.group(1))
                data['pct_CTOT'] = [float(ctot.group(1))]
            ctob = re.search(r"GA\/CT\/GA:\s(\d+)\s", line)
            if ctob:
                # print('num CTOB: ', ctob.group(1))
                data['pct_CTOB'] = [float(ctob.group(1))]
            ob = re.search(r"CT\/GA\/GA:\s(\d+)\s", line)
            if ob:
                # print('num OB: ', ob.group(1))
                data['pct_OB'] = [float(ob.group(1))]
    totalAligned = data['pct_OT'][0] + data['pct_CTOT'][0] + data['pct_CTOB'][0] + data['pct_OB'][0]
    return 100 * pd.DataFrame(data=data) / totalAligned


# Parses deduplication report from deduplicate_bismark command
# input String {dedupReport} path to deduplication report

#def parseDedupReport(dedupReport):
#    data = {}
#    with open(dedupReport, 'r') as report:
#        for line in report:
#            dupPercent = re.search(r"Total\snumber\sduplicated\salignments\sremoved:\s\d+\s\((\d*\.*\d*)%", line)
#            if dupPercent:
#                data['pct_umi_dup'] = [dupPercent.group(1)]
#    return pd.DataFrame(data=data)

# Parses the multiqc_general_stats file from multiQC done on raw and trimmed reads.
# expects rows 1-2 to be for raw reads, and rows 3-4 to be for trimmed reads
# input String {multiqc_general_stats} path to multiqc output multiqc_general_stats.txt

def parseMultiQCReport(multiqc_general_stats):
    data = {}
    stat_table = pd.read_csv(multiqc_general_stats, delimiter='\t')
    seqCount = stat_table['FastQC_mqc-generalstats-fastqc-total_sequences']
    data['reads_raw'] = int((seqCount[2] + seqCount[3])/2)
    pct_trimmed_R1 = 100 * (1 - seqCount[4] / seqCount[2])
    pct_trimmed_R2 = 100 * (1 - seqCount[5] / seqCount[3])
    data['pct_trimmed'] = round((pct_trimmed_R1 + pct_trimmed_R2)/2,3)
    print (data['pct_trimmed'])
    data['reads'] = int((seqCount[4] + seqCount[5])/2)
    print (data['reads'])
    trimmed_bases=stat_table['Cutadapt_mqc-generalstats-cutadapt-percent_trimmed']
    pct_trimmed_bases=round((trimmed_bases[0]+trimmed_bases[1])/2,3)
    data['pct_trimmed_bases']=pct_trimmed_bases
    print (data)
    
    gc=stat_table['FastQC_mqc-generalstats-fastqc-percent_gc']
    pct_gc=round((gc[4]+gc[5])/2,3)
    data['pct_GC']=pct_gc

    dup_sequence=stat_table['FastQC_mqc-generalstats-fastqc-percent_duplicates']
    pct_dup_sequence=round((dup_sequence[4]+dup_sequence[5])/2,3)
    data['pct_dup_sequence']=pct_dup_sequence

    pct_removed = 100 - ((data['reads']/data['reads_raw'])*100)
    pct_removed = round(pct_removed,3)
    data['pct_removed'] = pct_removed

    return pd.DataFrame(data,index=[0])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Script to collect RRBS qc metrics. \
    Usage: python3 collect_qc_metrics.py \
    --summary bismark_summary_report.txt \
    --bt2 90044015503_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt \
    --lambda spikeIn/bismark_summary_report.txt \
    --multiqc multiQC_report/multiqc_data/multiqc_general_stats.txt \
    --dedup 90044015503_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplication_report.txt \
    --tg 90044015503_trim.log')
    parser.add_argument('--summary',help='path to bismark2summary alignment report to species')
    parser.add_argument('--bt2',help='path to bowtie2 paired end alignment report to species')
    parser.add_argument('--lambda_summary',help='path to bismark2summary alignment report to lambda')
    parser.add_argument('--multiqc',help='path to multiQC report generated on pre and post trimmed reads')
#    parser.add_argument('--dedup',help='path to deduplicate_bismark report (umi mode)')
#    parser.add_argument('--dedup_lambda',help='path to deduplicate_bismark report (umi mode) for lambda')
    parser.add_argument('--tg',help='path to trim galore trimming report')
    parser.add_argument('--td',help='path to Trim Diversity Adapter trimming report')
    parser.add_argument('--phix_report',help='phix alignment report')
    parser.add_argument('--mapped_report',help='chr info report')
    args = parser.parse_args()

    sampleSummary = parseBismarkSummary(args.summary)
    fourStrandData = get4StrandMapData(args.bt2)
    spikeInSummary = parseBismarkSummary(args.lambda_summary)
#    dedupReport = parseDedupReport(args.dedup)
#    dedupReport_lambda = parseDedupReport(args.dedup_lambda)
    multiQCData = parseMultiQCReport(args.multiqc)
    trimData = parseTrimGaloreLog(args.tg)
    mspiData = parseTrimDiversityLog(args.td)[0]
    name=os.path.basename(args.tg)
    SID = (name).split("_")[0]   
    print (SID)
    print ("Parsed all arguments successfully")
    total = parseTrimDiversityLog(args.td)[1]
    #Compute pct_trimmed
    pct_trimmed = 100-((total/multiQCData['reads_raw'])*100)

    # Compute % mapped to various chromosomes
    df_mapped=pd.read_csv(args.mapped_report,sep="\t",header=0)
    
    # %phix
    df_phix=pd.read_csv(args.phix_report,sep="\t",header=0)
    df_phix["pct_phix"]=df_phix["pct_phix"].str.replace("%",'')
    pct_phix=df_phix["pct_phix"][0]
    

    # Dictionary of RRBS QC Metrics
    qcData = {
	'SID': [SID],
	'reads_raw': multiQCData['reads_raw'],
        'pct_adapter_detected': trimData['pct_adapter_detected'],
        'pct_trimmed' : round(pct_trimmed,3),
        'pct_no_MSPI' : mspiData['pct_no_MSPI'],
        'pct_trimmed_bases': multiQCData['pct_trimmed_bases'],
        'pct_removed' : multiQCData['pct_removed'],
	'reads': multiQCData['reads'],
        'pct_GC': multiQCData['pct_GC'],
        'pct_dup_sequence': multiQCData['pct_dup_sequence'],
        'pct_phix': pct_phix,
        'pct_chrX': round(df_mapped['pct_chrX'],3),
        'pct_chrY': round(df_mapped['pct_chrY'],5),
        'pct_chrM': round(df_mapped['pct_chrM'],3),
        'pct_chrAuto': round(df_mapped['pct_chrAuto'],3),
        'pct_contig': round(df_mapped['pct_contig'],3),
        'pct_Uniq': round(sampleSummary['pct_Uniq'],3),
	'pct_Unaligned': round(sampleSummary['pct_Unaligned'],3),
	'pct_Ambi': round(sampleSummary['pct_Ambi'],3),
        'pct_OT': round(fourStrandData['pct_OT'],3),
        'pct_OB': round(fourStrandData['pct_OB'],3),
        'pct_CTOT': round(fourStrandData['pct_CTOT'],3),
        'pct_CTOB': round(fourStrandData['pct_CTOB'],3),
        'pct_umi_dup': round(sampleSummary['pct_umi_dup'],3),
	'pct_CpG': round(sampleSummary['pct_CpG'],3),
	'pct_CHG': round(sampleSummary['pct_CHG'],3),
	'pct_CHH': round(sampleSummary['pct_CHH'],3),
        'lambda_pct_Uniq': round(spikeInSummary['pct_Uniq'],3),
        'lambda_pct_Ambi': round(spikeInSummary['pct_Ambi'],3),
        'lambda_pct_umi_dup': round(spikeInSummary['pct_umi_dup'],3),
        'lambda_pct_CpG': round(spikeInSummary['pct_CpG'],3),
        'lambda_pct_CHG': round(spikeInSummary['pct_CHG'],3),
        'lambda_pct_CHH': round(spikeInSummary['pct_CHH'],3)
	} 
#    print (qcData)
   # Save qc metrics to ${SID}_qcmetrics.csv file
    qcDataFrame = pd.DataFrame(qcData)
    print(qcDataFrame)
    print(SID+"_qcmetrics.csv")
    qcDataFrame.to_csv(SID+'_qcmetrics.csv', index=False)
   
