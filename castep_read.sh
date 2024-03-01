echo "The numbers of unit in the system:"
read NU
echo "Filename:"
read FI
grep "Aniso(ppm)" Na3PS4.castep -A ${NU} | sed "s/|//" > read.txt