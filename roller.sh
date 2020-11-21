# Set defaults
NUM=1		# Number of dice
DIE=6		# Faces per die
PLU=0		# Flat modifier
REP=1		# Repetitions
VER=false	# Verbose
CRI=false	# Crits

# Print usage
usage() {
	echo "Usage: ./roller.sh [-n Number] [-d Die] [-p Modifier] [-r Repetitions] [-cv]"
	echo " -n: Number of dice"
	echo " -d: Faces per die"
	echo " -p: Flat modifier"
	echo " -r: Repetitions"
	echo " -c: Criticals"
	echo " -v: Verbose"
}

# Process args
while getopts 'n:d:p:r:cv' opt; do
	case $opt in
		n) NUM=$OPTARG ;;
		d) DIE=$OPTARG ;;
		p) PLU=$OPTARG ;;
		r) REP=$OPTARG ;;
		c) CRI=true ;;
		v) VER=true ;;
		:) usage; exit 1 ;;
		?) usage; exit 1 ;;
	esac
done

# Print back what should be rolled
ROLLREPORT="Rolling: $NUM""d$DIE"
if [ $PLU -ne 0 ]; then ROLLREPORT="$ROLLREPORT+$PLU"; fi
if [ $REP -ne 1 ]; then ROLLREPORT="$ROLLREPORT x$REP"; fi
echo "$ROLLREPORT"

# Roll the dice
# Iterate across repetitions
for i in $(seq 1 $REP); do

	# Print repetition header if relevant
	if [ $REP -ne 1 ]; then
		echo "Round $i:"
	fi

	# Reset total for new repetition; iterate across die rolls
	TOTAL=0
	for j in $(seq 1 $NUM); do

		# Get a random number from /dev/random
		ROLL="$(od -An -N4 -i /dev/random)"

		# Make sure it's not negative (shell numbers are signed)
		if [ $ROLL -lt 0 ]; then
			ROLL="$(( $ROLL * -1 ))"
		fi

		# Constrain random value to die range
		ROLL="$(( $(( $ROLL % $DIE )) + 1 ))"
		#ROLL="$(( $ROLL + 1 ))"

		# Find out if crit (-1 failure, 1 success)
		CRIT=0
		if [ $CRI = true ] && [ $DIE -eq 20 ]; then
			if [ $ROLL -eq 1 ]; then
				CRIT=-1
			elif [ $ROLL -ge 20 ]; then
				CRIT=1
			fi
		fi

		# Print if verbose or crit
		ROLLREPORT=""
		if [ $VER = true ]; then
			ROLLREPORT="|Roll $j: $ROLL"
			if [ $CRIT -ne 0 ]; then
				ROLLREPORT="$ROLLREPORT; "
			fi
		fi

		if [ $CRIT -eq -1 ]; then
			ROLLREPORT="$ROLLREPORT""Critical failure! :^["
		elif [ $CRIT -eq 1 ]; then
			ROLLREPORT="$ROLLREPORT""Critical success! :^]"
		fi

		if [ $VER = true ] || [ $CRIT -ne 0 ]; then
			echo "$ROLLREPORT"
		fi

		#Sum new roll to total
		TOTAL="$(( $TOTAL + $ROLL ))"
	done

	# Add modifier; print result
	TOTAL="$(( $TOTAL + $PLU ))"
	if [ $REP -ne 1 ]; then
		echo "\\-Result $i: $TOTAL"
	else
		echo "\\-Result: $TOTAL"
	fi
done
