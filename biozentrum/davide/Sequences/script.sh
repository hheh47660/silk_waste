file=$1
output=$2

i=1
for line in $(cat $file); do
	echo ">$i" #>> $output
	echo $line #>> $output

	i=$(($i+1))	
done
