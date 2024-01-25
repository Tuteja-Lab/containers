#!/bin/bash
set -beEu -o pipefail

# ---- Dependencies
# kentSrc: faSize, faUnmask.pl, faSplit
# tfbsAnalysisPipeline: randomlySampleGcMatch, placeNsInShuffledSeqs
# vendor: squidShuffle

prog="`basename $0`"

# ---- Default parameter values.
nullType="gc"
nullSize="10"
tmpRoot="/tmp/null.XXXXXXXXXX"
hub="hoxa"
disableCluster=0
splitSize=25

usage() {
    echo "$prog - Generate a null set with similar properties to the input fasta set." > /dev/stderr
    echo "usage:" > /dev/stderr
    echo "   $prog {options} input.fa output.fa" > /dev/stderr
    echo "" > /dev/stderr
    echo "options:" > /dev/stderr
    echo "   -n s, --nullType=s     Null model to use (default: $nullType)." > /dev/stderr
    echo "                           Options: s1 - mono-nucleotide shuffled" > /dev/stderr
    echo "                                    s2 - di-nucleotide shuffled" > /dev/stderr
    echo "                                    m0 - 0th order Markov properties" > /dev/stderr
    echo "                                    m1 - 1th order Markov properties" > /dev/stderr
    echo "                                    gc - GC matched" > /dev/stderr
    echo "   -z n, --nullSize=n     Number of shuffles per input sequence (must be > 0) (default: $nullSize)." > /dev/stderr
    echo "   -e s, --excludeFile=s  Bed file of regions to exclude from sampling under gc-matching. (default: NONE)." > /dev/stderr
    echo "   -g s, --genome=s       The genome to GC-match from. MANDATORY for gc-matching (default: NONE)." > /dev/stderr
    echo "                           Will look in /LAS/gbdb-bej/<genome>/<genome>.2bit." > /dev/stderr
    echo "   -f s, --twoBitFile=s   File to use instead of genome. --genome is ignored if this is provided (default: NONE)." > /dev/stderr
    echo "   -t s, --tmpRoot=pre    Temporary directory root (default: $tmpRoot)." > /dev/stderr
    echo "   -h s, --hub=hub        Parasol cluster hub (default: $hub)." > /dev/stderr
    echo "   -d,   --disableCluster Don't run the jobs on the cluster." > /dev/stderr
    echo "   -s n, --splitSize=n    Number of sequences per cluster job (default: $splitSize)." > /dev/stderr
    echo "" > /dev/stderr
    exit 1
}

# ---- Parse the command line parameters.
ARGS=$(getopt -o n:z:e:g:f:t:h:ds: -l "nullType:,nullSize:,excludeFile:,genome:,twoBitFile:,tmpRoot:,hub:,disableCluster,splitSize:" -n "$prog" -- "$@");

# ---- Exit if bad arguments
if [ $? -ne 0 ]; then
    usage $0
fi

eval set -- "$ARGS"; 

while true; do
	case "$1" in
		-n|--nullType)
			shift;
			nullType=$1;
			shift;
			case "$nullType" in
				s1) nullType=""
				;;
				s2)	nullType="-d"
				;;
				m0)	nullType="-0"
				;;
				m1)	nullType="-1"
				;;
				gc) nullType="gc"
				;;
				*) 
				echo "-n, --nullType must be either s1, s2, m0, m1 or gc" > /dev/stderr
				exit 1
				;;
			esac
			;;
		-z|--nullSize)
			shift;
			nullSize=$1;
			shift;
			if [ $nullSize -le 0 ]; then
				echo "-z n, --nullSize=n; Needs to be > 0." > /dev/stderr
				exit 1
			fi
			;;
		-e|--excludeFile)
			shift;
			excludeFile=$1;
			shift;
			;;
		-g|--genome)
			shift;
			genome=$1;
			shift;
			;;
		-f|--twoBitFile)
			shift;
			twoBitFile=$1;
			shift;
			;;
		-t|--tmpRoot)
			shift;
			tmpRoot=$1;
			shift;
			;;
		-h|--hub)
			shift;
			hub=$1;
			shift;
			;;
		-d|--disableCluster)
			disableCluster=1;
			shift;
			;;
		-s|--splitSize)
			shift;
			splitSize=$1;
			shift;
			;;
		--)
			shift;
			break;
			;;
	esac
done

if [ $# -ne 2 ]; then
	usage $0
fi

if [ "$nullType" == "gc" ]; then
	# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02
	if [ -n "${twoBitFile:-}" ]; then
		twoBitFile=`readlink -ev $twoBitFile`
	elif [ -n "${genome:-}" ]; then
		twoBitFile=`readlink -ev /cluster/gbdb-bej/$genome/${genome}.2bit`
	else
		echo "-g, --genome or -f, --twoBitFile are needed with with gc-matching." > /dev/stderr
		exit 1
	fi
fi

inputFn=$1;
outputFn=$2;
tmpDir=`mktemp -d $tmpRoot`
tmpDir=`readlink -ev $tmpDir`
cat $inputFn >| $tmpDir/input.fa
inputFn=`readlink -ev $tmpDir/input.fa`
numSeq=`faSize -tab $inputFn  | awk '{if($1=="seqCount") print $2}'`
numBreaks=`echo $numSeq / $splitSize | bc`
if [ $numBreaks -eq 0 ]; then
	numBreaks=1
fi

if [ -n "${excludeFile:-}" ]; then
	cat $excludeFile >| $tmpDir/exclude.bed
	excludeFile="-exclude=$(readlink -ev $tmpDir/exclude.bed)"
else
	excludeFile=""
fi


# ---- Upper case all characters and create "script" that will do match-ing
# ---- no need for placeNsInShuffledSeqs for randomlySampleGcMatch since it does that automatically
if [ "$nullType" != "gc" ]; then
	cat <<-EOF >| $tmpDir/match.sh
		#!/bin/bash
		set -beEu -o pipefail
		faUnmask.pl \$1 | awk '{ if (substr(\$0,0,1) != ">") { gsub("N|n|X|x","",\$0); } print \$0; }' |\\
		  squidShuffle $nullType -n $nullSize --informat FASTA /dev/stdin | placeNsInShuffledSeqs \$1 stdin stdout |\\
		  awk 'BEGIN {prev=""; ct=0; } { if (substr(\$0,0,1) == ">") { if (\$0 != prev) { ct=0; } ct++; print \$0 "." ct; prev=\$0; } else { print \$0; } }' | faUnmask.pl /dev/stdin >| \$2
	EOF
else
	cat <<-EOF >| $tmpDir/match.sh
		#!/bin/bash
		set -beEu -o pipefail
		faUnmask.pl \$1 | randomlySampleGcMatch -seed=\$3 -includeCoords -noRandom -noHap -noM -noXY -samples=$nullSize $excludeFile stdin $twoBitFile stdout | faUnmask.pl /dev/stdin >| \$2
		#faUnmask.pl \$1 | randomlySampleGcMatch -includeCoords -noRandom -noHap -noM -noXY -samples=$nullSize $excludeFile stdin $twoBitFile stdout | faUnmask.pl /dev/stdin >| \$2
	EOF
fi
chmod a+x $tmpDir/match.sh

# ---- Perform match
if [ $disableCluster -eq 1 ]; then
	$tmpDir/match.sh $inputFn $outputFn $((1 + RANDOM % 1000))
else
	mkdir $tmpDir/splitFa $tmpDir/par
	faSplit sequence $inputFn $numBreaks $tmpDir/splitFa/split_ 
	#find $tmpDir/splitFa -type f | xargs -i echo "$tmpDir/match.sh {} {}_null.fa" >| $tmpDir/par/joblist
	find $tmpDir/splitFa -type f | awk -v v1=$tmpDir 'BEGIN{srand(); n=1000000;} {printf "%s/match.sh "$0" "$0"_null.fa %6d\n", v1,rand()*n}' >| $tmpDir/par/joblist
	ssh $hub "cd $tmpDir/par && para -batch=$tmpDir/par make $tmpDir/par/joblist" # not sure why the cd $tmpDir/par is needed for some users and not others
	find $tmpDir/splitFa -type f -name '*_null.fa' | xargs cat >| $outputFn
fi

# ---- Cleanup temp space
rm -rf $tmpDir

