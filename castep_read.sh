echo "The numbers of unit in the system:"
read NU
echo "Filename:"
read FI
grep "Cq(MHz)" ${FI}.castep -A ${NU} | sed "s/|//" > read.txt