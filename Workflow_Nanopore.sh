#!/bin/sh
# Posix Shell script
# tested with bash, dash

# check deps for script 
command -v dialog || exit 1
command -v porechop || exit 1 
command -v multi_to_single_fast5 || exit 1
command -v deepbinner || exit 1
command -v wtdbg2 || exit 1
command -v samtools || exit 1

about(){
echo " $0 script"
echo "Usage: $0 <working directory> <raw data directory> <project name>"
echo "written by Johannes Hausmann, original written by A. Krause"
}
if [ $# -ge 3 ]; then
	echo $1 $2 $3
else
	about && exit 1 
fi

project=$3

echo "create working directory (if not already exists)"
mkdir -p $1

echo "checking raw data directory"
[ -d $2 ] || exit 1

echo "checking working directory"
[ -d $1 ] || exit 1

echo "change to workdir"
cd $1 || exit 1

# get current date in ISO 8601
d=$(date -I)

# create log file header
# Workflow_Nanopore
# Date: 29-07-19
# User: jhausmann@bioserver
# ------

echo "$0 log file" >> "$0-$d".log
echo "Date: $d" >> "$0-$d".log
echo "User: $(whoami) at $(hostname)" >> "$0-$d".log
echo "-----" >> "$0-$d".log

echo "creating subdirectories"
mkdir -p Porechop_$d Deepbinner_$d Multi_to_single_fast5_$d canu_$d shasta_$d blast_$d wtdbg2_$d

# --create tree view and add it to log file--
tree -L 2 >> "$0-$d".log
echo "-----" >> "$0-$d".log

# ---------- Porechop ----------

cd Porechop_"$d" || exit 1

echo "concatenate fastq files for porechop" | tee -a ../"$0-$d".log
cat "$2"/fastq_pass/*.fastq > "$project".fastq

echo "gzip fastq file $project.fastq" | tee -a ../"$0-$d".log
gzip "$project".fastq

echo "detect barcodes in fastq sequences with Porechop" | tee -a ../"$0-$d".log
nohup porechop -i "$project".fastq.gz -b . > Porechop.out 2> Porechop.err

cd .. || exit 1

# ---------- Multi_to_single_fast5 ----------

cd Multi_to_single_fast5_"$d" || exit 1

echo "split fast5 files into single sequence files" | tee -a ../"$0-$d".log
nohup multi_to_single_fast5 -i $2/fast5_pass -s . > ./M2S.out 2> ./M2S.err

cd .. || exit 1

# ---------- Deepbinner ----------

cd Deepbinner_"$d"

echo "detect barcodes in fast5 sequences with deepbinner" || tee -a ../"$0-$d".log
nohup deepbinner classify --rapid ../Multi_to_single_fast5_"$d"/ > deepbinner_classify_"$project".out 2> deepbinner_classify_"$project".err

echo "bin fastq sequences according to deepbinner basrcodes" || tee -a ../"$0-$d".log
nohup deepbinner bin --classes deepbinner_classify_"$project".out --reads ../Porechop_"$d"/"$project".fastq.gz --out_dir .

cd .. || exit 1

# ---------- wtdbg2 ----------

cd wtdbg2_"$d"

# wtdbg2 assembler
for i in ../Porechop_"$d"/BC*.fastq.gz; do
	f=$(basename "$i" .fastq.gz)
	nohup wtdbg2 -i "$i" -o "$project_$f"
#wtpoa-cns derive consensus sequence
for i  "$project"_*
do
wtpoa-cns
done

	#blastn
	#BlastToSam.jar
	#samtools
done


