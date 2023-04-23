# !/bin/bash
# The script is a bash script that processes some CSV files in a source directory based on a date range and creates a new CSV file with the results in an output directory. 
# It also uses SCP to transfer the output file to a remote server.
# Usage: bash bulkLoad.sh -s <source_dir> -o <output_dir> -b <start_date> -e <end_date> -r <server> -p <remote_path>
# Options:
#   -s  Source directory (default: src)
#   -o  Output directory (default: output)
#   -b  Start date in yyyymmdd format (default: 20221227)
#   -e  End date in yyyymmdd format (default: 20230331)
#   -r  Remote server (default: pontis@10.76.220.33)
#   -p  Remote path (default: /var/tmp/simreg)
#   -h  Print this help message

source_dir=src
output_dir=output
start_date="20221227"
end_date="20230331"
server=pontis@10.76.220.33
remote_path=/var/tmp/simreg

while getopts "hs:o:b:e:r:p:" opt; do
  case $opt in
    h)
      echo "Usage: ./bulkLoad.sh -s <source_dir> -o <output_dir> -b <start_date> -e <end_date> -r <server> -p <remote_path>"
      exit 0
      ;;
    s)
      source_dir=$OPTARG
      ;;
    o)
      output_dir=$OPTARG
      ;;
    b)
      start_date=$OPTARG
      ;;
    e)
      end_date=$OPTARG
      ;;
    r)
      server=$OPTARG
      ;;
    p)
      remote_path=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

now=$(date +"%Y%m%d_%H%M")
handle_error() {
    local exit_code=$1
    local error_msg=$2
    echo "ERROR: $error_msg"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: $error_msg" >> error.log
    exit "$exit_code"
}

if [ ! -d "$output_dir" ]; then
    mkdir "$output_dir"
fi


echo "MIN|REGISTRATION STATUS TIMESTAMP" > "$output_dir/AIA_Input_SIM_Reg_${now}.csv"
current="$start_date"
while [[ "$current" -le "$end_date" ]]; do
    echo -e "\n++++++++++++++++++++++++++++++"
    echo "Start processing for: $current"
    echo "++++++++++++++++++++++++++++++"
    file=$(find "$source_dir" -name "Postpaid_2waySMSReply_${current}_*.csv.gz")
    if [ -n "$file" ]; then
        for f in $file; do
            echo "Processing file: $f"
              gunzip -c "$f" | (awk -F '|' 'tolower($8) == "yes" && (tolower($3) == "pd_sim_reg" || tolower($3) == "pd_sim_reg_3gb" || tolower($3) == "pd_sim_reg_3gb_otherchannel" || tolower($3) == "pd_sim_reg_3gb_5858" || tolower($3) == "pd_simreg_massiveivrs_precall") { print $1 "|" $9 }') >> "$output_dir/AIA_Input_SIM_Reg_${now}.csv" || \
                handle_error 5 "Error processing file '$f'"
        done
    else
        echo "No Found"
    fi
    current=$(date -d "$current + 1 day" +%Y%m%d)
done
scp "$output_dir/AIA_Input_SIM_Reg_${now}.csv" "$server:$remote_path"