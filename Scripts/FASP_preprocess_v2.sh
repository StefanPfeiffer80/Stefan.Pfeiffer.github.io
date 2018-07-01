# FASP_peprocessing_v1 file; written by Stefan Pfeiffer, 1.December 2017, last modified on 30.June 2018
# Contact: microbiawesome@gmail.com; 
# Copyright (C) Stefan Pfeiffer, 2016-2018, all rights reserved.
# FASP is a workflow for analysing Illumina paired-end sequence data. 
# This file is distributed without warranty
# This file runs as a Linux bashscript; 
# Cite as: Pfeiffer, S. (2018) FASPA - Fast Amplicon Sequence Processing and Analyses, DOI:10.5281/yenodo.1302800

set -e
set -o pipefail

# 1.Merge reads: All read pairs will be merged into a single file
./US_10.240 -fastq_mergepairs *_R1_001.fastq \-fastqout raw.fq -relabel @ 
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Read pairs are merged successfully!!!! Output file: raw.fq"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
# 2. Find out at which positions your primers are
vsearch  -fastx_subsample raw.fq -sample_size 100 -fastqout raw_subset_100.fq # The subset sample size can be changed, default is 100
./US_10.240  -search_oligodb raw_subset_100.fq -db primers.fa -strand both -userout primer_positions.txt -userfields query+qlo+qhi+qstrand
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Did you check the length of your primers and the expected size of your amplicons?"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
# 6. Removal of primers + adapters
while getopts ":l:r:m:s:" opt
   do
     case $opt in
        l ) primerleft=$OPTARG;;
        r ) primerright=$OPTARG;;
	m ) max=$OPTARG;;
	s ) min=$OPTARG;;
     esac
done
### In this line you have to insert the lenght of your forward primer at the first XX position (e.g. --fastq_stripleft 19)
### The reverse primer length has tobe inserted at the second XX position (e.g. --fastq_stripright 20)
### You have also to enter the minimum length of your sequences and the maximum lenght of your sequences. Due to differences in 16S amplicon length you should use a frame of 50-100 base pair positions (e.g. 300-360 for an amplicon of the expected size of 330 bp). 
vsearch -fastq_filter raw.fq --fastq_stripleft $primerleft --fastq_stripright $primerright --fastq_maxlen $max --fastq_minlen $min --fastaout fileredstripped.fa
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Successful, low quality reads were removed; Output file: filteredstripped.fa"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
# 7.Extracting uniques sequences: 
./US_10.240 -fastx_uniques filteredstripped.fa -sizeout -relabel Uniq -fastaout uniques.fa # output file is "uniques.fa"
echo "Successful; The file uniques.fa contains your unique read seuqences; Next comes denoising (bash FASP_unoise.sh)or OTU clusetring (bash FASP_uparse.sh)"