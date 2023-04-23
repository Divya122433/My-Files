current=20221227
end=20230331

while [ "$current" -le "$end" ]
do
    filename="Postpaid_2waySMSReply_${current}_0000.csv"
    echo "639399175267|Smart Postpaid|PD_SIM_REG_3GB|||||YES|$current 00:00:00|Success" > "$filename"
    gzip "$filename"
    filename="Postpaid_2waySMSReply_${current}_1200.csv"
    echo "639399175267|Smart Postpaid|PD_SIM_REG_3GB|||||YES|$current 12:00:00|Success" > "$filename"
    gzip "$filename"
    current=$(date -d "$current + 1 day" +%Y%m%d)
done