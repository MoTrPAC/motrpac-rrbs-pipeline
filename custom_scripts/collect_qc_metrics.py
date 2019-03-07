# Author: Samir Akre
# Purpose: 
#   The goal of this script is to agregate QC metrics for the motrpac RRBS initial processing pipeline. Read the usage() function for details on usage.
# Output:
#   writes csv file: '${SID}_qcmetrics.csv' where ${SID} is based on the sample ID sent as input with -u or --sid

import sys
import getopt
import csv
import re
import pandas as pd


# Print usage instructions to stdout
def usage():
    print('')
    print('Collect QC Metrics Script Usage')
    print('')
    print('*** Required inputs ***')
    print('--sid, -u: Sample ID (SID)')
    print('--sample, -s: path to bismark2summary alignment report to species')
    print('--bt2, -b: path to bowtie2 paired end alignment report to species')
    print('--lambda, -l: path to bismark2summary alignment report to lambda')
    print('--multiqc, -m: path to multiQC report generated on pre and post trimmed reads')
    print('--dedup, -d: path to deduplicate_bismark report (umi mode)')
    print('')
    print('Example Command: ')
    print('''
    python collect_qc_metrics.py \\
        -u SID \\
        -s sample/bismark_summary_report.txt \\
        -bt2 sample/SID_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt \\
        -l spikeIn/bismark_summary_report.txt \\
        -m multiqc_data/multiqc_general_stats.txt \\
        -d sample/SID_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplication_report.txt
    ''')


# Parse bismark_summary_report.txt file for RRBS QC metrics
# input String {bismarkSummary} path to file containing output from bismark2summary ran on alignment
def parseBismarkSummary(bismarkSummary):
    report_table = pd.read_csv(bismarkSummary, delimiter='\t')
    # for col in report_table.columns:
    #    print(col, ': ', report_table[col].values[0])
    data = {}
    unMetCs = report_table['Unmethylated CpGs'] + report_table['Unmethylated chgs'] + report_table['Unmethylated CHHs']
    eff = unMetCs / report_table['Total Cs']
    data['Aligned Reads'] = report_table['Aligned Reads']
    data['%Aligned'] = [100*(report_table['Aligned Reads'] / report_table['Total Reads']).values[0]]
    data['%Unaligned'] = [100*(report_table['Unaligned Reads'] / report_table['Total Reads']).values[0]]
    data['%Ambi'] = [100*(report_table['Ambiguously Aligned Reads'] / report_table['Total Reads']).values[0]]
    data['%CpG'] = [100*(report_table['Methylated CpGs'] / (report_table['Unmethylated CpGs'] + report_table['Methylated CpGs'])).values[0]]
    data['%CHG'] = [100*(report_table['Methylated chgs'] / (report_table['Unmethylated chgs'] + report_table['Methylated chgs'])).values[0]]
    data['%CHH'] = [100*(report_table['Methylated CHHs'] / (report_table['Unmethylated CHHs'] + report_table['Methylated CHHs'])).values[0]]
    data['%eff'] = [100*eff.values[0]]
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
                data['%OT'] = [float(ot.group(1))]
            ctot = re.search(r"GA\/CT\/CT:\s(\d+)\s", line)
            if ctot:
                # print('num CTOT: ', ctot.group(1))
                data['%CTOT'] = [float(ctot.group(1))]
            ctob = re.search(r"GA\/CT\/GA:\s(\d+)\s", line)
            if ctob:
                # print('num CTOB: ', ctob.group(1))
                data['%CTOB'] = [float(ctob.group(1))]
            ob = re.search(r"CT\/GA\/GA:\s(\d+)\s", line)
            if ob:
                # print('num OB: ', ob.group(1))
                data['%OB'] = [float(ob.group(1))]
    totalAligned = data['%OT'][0] + data['%CTOT'][0] + data['%CTOB'][0] + data['%OB'][0]
    return 100 * pd.DataFrame(data=data) / totalAligned


# Parses deduplication report from deduplicate_bismark command
# input String {dedupReport} path to deduplication report
def parseDedupReport(dedupReport):
    data = {}
    with open(dedupReport, 'r') as report:
        for line in report:
            dupPercent = re.search(r"Total\snumber\sduplicated\salignments\sremoved:\s\d+\s\((\d*\.*\d*)%", line)
            if dupPercent:
                # print('% Duplication: ', dupPercent.group(1))
                data['% of UMI dup'] = [dupPercent.group(1)]
    return pd.DataFrame(data=data)


# Parses the multiqc_general_stats file from multiQC done on raw and trimmed reads.
# expects rows 1-2 to be for raw reads, and rows 3-4 to be for trimmed reads
# input String {multiqc_general_stats} path to multiqc output multiqc_general_stats.txt
def parseMultiQCReport(multiqc_general_stats):
    data = {}
    stat_table = pd.read_csv(multiqc_general_stats, delimiter='\t')
    # for col in stat_table.columns:
        # print(col, ': ', stat_table[col].values[0])
    seqCount = stat_table['FastQC_mqc-generalstats-fastqc-total_sequences']
    data['reads_raw_R1'] = [seqCount[0]]
    data['reads_raw_R2'] = [seqCount[1]]
    data['%trimmed_R1'] = [100 * (1 - seqCount[2] / seqCount[0])]
    data['%trimmed_R2'] = [100 * (1 - seqCount[3] / seqCount[1])]
    data['reads_R1'] = [seqCount[2]]
    data['reads_R2'] = [seqCount[3]]
    avgLength = stat_table['FastQC_mqc-generalstats-fastqc-avg_sequence_length']
    data['%trimmed_bases_R1'] = [100 * (1 - avgLength[2] / avgLength[0])]
    data['%trimmed_bases_R2'] = [100 * (1 - avgLength[3] / avgLength[1])]
    return pd.DataFrame(data)

def main(argv):
    sample_BT2_pe_report = ''
    sample_bismark_summary_report = ''
    lambda_bismark_summary_report = ''
    multiqc_general_stats = ''
    dedup_report = ''
    SID = ''

    # Check input arguments
    try:
        opts, args = getopt.getopt(argv, "hs:l:m:d:b:u:", ["sample=", "multiqc=", "lambda=","dedup=", "bt2=", "sid="])
    except getopt.GetoptError as err:
        print(str(err))
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            usage()
            sys.exit()
        elif opt in ("-s", "--sample"):
            sample_bismark_summary_report = arg
        elif opt in ("-b", "--bt2"):
            sample_BT2_pe_report = arg
        elif opt in ("-l", "--lambda"):
            lambda_bismark_summary_report = arg
        elif opt in ("-m", "--multiqc"):
            multiqc_general_stats = arg
        elif opt in ("-d", "--dedup"):
            dedup_report = arg
        elif opt in ("-u", "--sid"):
            SID = arg

    # Print to std out the variables and their filenames for verifying inputs
    print('SID: ', SID)
    print('sample bismark_summary_report: ', sample_bismark_summary_report)
    print('sample bt2_pe_report: ', sample_BT2_pe_report)
    print('lambda bismark_summary_report: ', lambda_bismark_summary_report)
    print('multiqc_general_stats: ', multiqc_general_stats)
    print('deduplication_report: ', dedup_report)

    # Check all required arguments input
    if not (len(SID) and len(sample_bismark_summary_report) and len(lambda_bismark_summary_report) and len(multiqc_general_stats) and len(dedup_report) and len(sample_BT2_pe_report)):
        print('Error: Missing input files')
        usage()
        sys.exit(2)

    # Parse files using above functions
    sampleSummary = parseBismarkSummary(sample_bismark_summary_report)
    fourStrandData = get4StrandMapData(sample_BT2_pe_report)
    spikeInSummary = parseBismarkSummary(lambda_bismark_summary_report)
    dedupReport = parseDedupReport(dedup_report)
    multiQCData = parseMultiQCReport(multiqc_general_stats)

    # Dictionary of RRBS QC Metrics
    qcData = {
        'SID': [SID],
        'reads_raw_R1': multiQCData['reads_raw_R1'],
        'reads_raw_R2': multiQCData['reads_raw_R2'],
        '%trimmed_R1': multiQCData['%trimmed_R1'],
        '%trimmed_R2': multiQCData['%trimmed_R2'],
        'reads_R1': multiQCData['reads_R1'],
        'reads_R2': multiQCData['reads_R2'],
        '%trimmed_bases_R1': multiQCData['%trimmed_bases_R1'],
        '%trimmed_bases_R2': multiQCData['%trimmed_bases_R2'],
        '%Aligned': sampleSummary['%Aligned'],
        '%Unaligned': sampleSummary['%Unaligned'],
        '%Ambi': sampleSummary['%Ambi'],
        '%CpG': sampleSummary['%CpG'],
        '%CHG': sampleSummary['%CHG'],
        '%CHH': sampleSummary['%CHH'],
        '%OT': fourStrandData['%OT'],
        '%CTOT': fourStrandData['%CTOT'],
        '%CTOB': fourStrandData['%CTOB'],
        '%OB': fourStrandData['%OB'],
        '% of UMI dup': dedupReport['% of UMI dup'],
        '%eff': spikeInSummary['%eff'],  # Efficiency at converting unmethylated C's during bisulfite conversion
        '%lambda': 100*spikeInSummary['Aligned Reads'] / (spikeInSummary['Aligned Reads'] + sampleSummary['Aligned Reads']),
    }

    # Save qc metrics to ${SID}_qcmetrics.csv file
    qcDataFrame = pd.DataFrame(qcData)
    print(qcDataFrame)
    qcDataFrame.to_csv(SID+'_qcmetrics.csv', index=False)

if __name__ == "__main__":
    main(sys.argv[1:])
