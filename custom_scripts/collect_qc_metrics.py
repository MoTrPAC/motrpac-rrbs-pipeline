import sys
import getopt
import csv
import re
import numpy as np
import pandas as pd


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
    data['%CpG'] = [(report_table['Methylated CpGs'] / report_table['Total Cs']).values[0]]
    data['%CHG'] = [(report_table['Methylated chgs'] / report_table['Total Cs']).values[0]]
    data['%CHH'] = [(report_table['Methylated CHHs'] / report_table['Total Cs']).values[0]]
    data['%eff'] = [100*eff.values[0]]
    return pd.DataFrame(data=data)


def get4StrandMapData(bismarkReport):
    data = {}
    with open(bismarkReport, 'r') as report:
        for line in report:
            ot = re.search(r"CT\/GA\/CT:\s(\d+)\s", line)
            if ot:
                # print('%OT: ', ot.group(1))
                data['%OT'] = [ot.group(1)]
            ctot = re.search(r"GA\/CT\/CT:\s(\d+)\s", line)
            if ctot:
                # print('%CTOT: ', ctot.group(1))
                data['%CTOT'] = [ctot.group(1)]
            ctob = re.search(r"GA\/CT\/GA:\s(\d+)\s", line)
            if ctob:
                # print('%CTOB: ', ctob.group(1))
                data['%CTOB'] = [ctob.group(1)]
            ob = re.search(r"CT\/GA\/GA:\s(\d+)\s", line)
            if ob:
                # print('%OB: ', ob.group(1))
                data['%OB'] = [ob.group(1)]
    return pd.DataFrame(data=data)


def parseDedupReport(dedupReport):
    data = {}
    with open(dedupReport, 'r') as report:
        for line in report:
            dupPercent = re.search(r"Total\snumber\sduplicated\salignments\sremoved:\s\d+\s\((\d*\.*\d*)%", line)
            if dupPercent:
                # print('% Duplication: ', dupPercent.group(1))
                data['% of UMI dup'] = [dupPercent.group(1)]
    return pd.DataFrame(data=data)


def parseMultiQCReport(multiqc_general_stats):
    data = {}
    stat_table = pd.read_csv(multiqc_general_stats, delimiter='\t')
    # for col in stat_table.columns:
        # print(col, ': ', stat_table[col].values[0])
    seqCount = stat_table['FastQC_mqc-generalstats-fastqc-total_sequences']
    data['reads_raw'] = [seqCount[0]]
    data['%trimmed'] = [100 * (1 - seqCount[2] / seqCount[0])]
    avgLength = stat_table['FastQC_mqc-generalstats-fastqc-avg_sequence_length']
    data['%trimmed_bases'] = [100 * (1 - avgLength[2] / avgLength[0])]
    return pd.DataFrame(data)

def main(argv):
    sample_BT2_pe_report = ''
    sample_bismark_summary_report = ''
    lambda_bismark_summary_report = ''
    multiqc_general_stats = ''
    dedup_report = ''
    SID = ''
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

    print('SID: ', SID)
    print('sample bismark_summary_report: ', sample_bismark_summary_report)
    print('sample bt2_pe_report: ', sample_BT2_pe_report)
    print('lambda bismark_summary_report: ', lambda_bismark_summary_report)
    print('multiqc_general_stats: ', multiqc_general_stats)
    print('deduplication_report: ', dedup_report)

    if not (len(SID) and len(sample_bismark_summary_report) and len(lambda_bismark_summary_report) and len(multiqc_general_stats) and len(dedup_report) and len(sample_BT2_pe_report)):
        print('Error: Missing input files')
        usage()
        sys.exit(2)

    sampleSummary = parseBismarkSummary(sample_bismark_summary_report)
    fourStrandData = get4StrandMapData(sample_BT2_pe_report)
    spikeInSummary = parseBismarkSummary(lambda_bismark_summary_report)
    dedupReport = parseDedupReport(dedup_report)
    multiQCData = parseMultiQCReport(multiqc_general_stats)
    qcData = {
        'SID': [SID],
        'reads_raw': multiQCData['reads_raw'],
        '%trimmed': multiQCData['%trimmed'],
        '%trimmed_bases': multiQCData['%trimmed_bases'],
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
    qcDataFrame = pd.DataFrame(qcData)
    print(qcDataFrame)
    qcDataFrame.to_csv(SID+'_qcmetrics.csv', index=False)

if __name__ == "__main__":
    # bismarkReport = '/Users/akre96/Documents/github/rrbs_bismark/sampleOutput/Muscle2_Outputs/sample/Muscle2_attached_R1_val_1.fq_trimmed_bismark_bt2_PE_report.txt'
    # bismarkSummary = '/Users/akre96/Documents/github/rrbs_bismark/sampleOutput/Muscle2_Outputs/sample/bismark_summary_report.txt'
    # spikeInBismarkSummary = '/Users/akre96/Documents/github/rrbs_bismark/sampleOutput/Muscle2_Outputs/spikeIn/bismark_summary_report.txt'
    # sampleDupReport = '/Users/akre96/Documents/github/rrbs_bismark/sampleOutput/Muscle2_Outputs/sample/Muscle2_attached_R1_val_1.fq_trimmed_bismark_bt2_pe.deduplication_report.txt'
    # multiQCReport = '/Users/akre96/Documents/github/rrbs_bismark/sampleOutput/Muscle2_Outputs/multiQC_report/multiqc_data/multiqc_general_stats.txt'
    # args = ['-u', 'Muscle2', '-s', bismarkSummary, '-b', bismarkReport, '-l', spikeInBismarkSummary, '-m', multiQCReport, '-d', sampleDupReport]
    # main(args)
    main(sys.argv[1:])
