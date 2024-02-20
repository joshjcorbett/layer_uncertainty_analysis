subs=("01" "02" "03" "04" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "24" "25" "26" "27" "28" "29" "30")

mkdir -p ../data/processed

for sub in ${subs[@]}
do 
	export sub=$sub
	Rscript individual_processing.R
done