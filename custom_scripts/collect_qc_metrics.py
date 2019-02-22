import sys
import getopt
import csv
import numpy as np
import pandas as pd


def usage():
    print('')
    print('Collect QC Metrics Script Usage')
    print('*** Required inputs ***')
    print('--species, -s: path to bismark alignment report to species')
    print('--lambda, -l: path to bismark alignment report to lambda')
    print('--multiqc, -m: path to multiQC report generated on pre and post trimmed reads')


def main(argv):
    speciesReport = ''
    lambdaReport = ''
    multiQC = ''
    try:
        opts, args = getopt.getopt(argv, "hs:l:m:", ["species=", "multiqc=", "lambda="])
    except getopt.GetoptError as err:
        print(str(err))
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            usage()
            sys.exit()
        elif opt in ("-s", "--species"):
            speciesReport = arg
        elif opt in ("-l", "--lambda"):
            lambdaReport = arg
        elif opt in ("-m", "--multiqc"):
            multiQC = arg
    if not (len(speciesReport) and len(lambdaReport) and len(multiQC)):
        usage()
        sys.exit(2)
    print('species file is "', speciesReport)
    print('lambda file is "', lambdaReport)
    print('multiqc file is "', multiQC)


def parseBismarkReport(bismarkReport):
    report_table = pd.read_csv(bismarkReport, delimiter='\t')
    print(report_table)
    print(report_table.columns)
        
if __name__ == "__main__":
    bismarkReport = '/Users/akre96/Documents/github/rrbs_bismark/sampleOutput/Muscle2_1000ksub_bismark_summary_report.txt'
    parseBismarkReport(bismarkReport)
    #main(sys.argv[1:])
