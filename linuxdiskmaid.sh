#!/bin/bash

before_cleanup_size=$(df -h --output=avail / | awk 'NR==2 {print $1}' | numfmt --from=auto)
export k=root
echo " "
echo "Greetings, fearless user! Welcome to the LinuxDiskMaid 😈, where disk cleaning is no joke, but we promise it won't bite! 🦇"
echo "---------------------------------------------------------------------"
echo " "
# Suppress error messages for empty array
shopt -s nullglob
users=($(getent passwd | awk -F: '$3 >= 1000 && $1 != "nobody" { print $1 }'))


LOG_DIRS=($(find  /var/log /$k/.npm/_logs  "${users[@]/#/\/home\/}/.npm/_logs" -type d -exec sh -c '[ -n "$(find "{}" -maxdepth 1 -type f -name  "*.log*" -print -quit)" ]' \; -print))

EXCLUDED_DIR=["/var/log/installer"]

# Days
MAX_AGE=7
MIN_AGE=5

# Process 1**
for LOG_DIR in "${LOG_DIRS[@]}"; do
    if [ -n "$LOG_DIR" ]; then
        if [ "$LOG_DIR" == "$EXCLUDED_DIR" ]; then
            echo "Skipping log cleaning for $LOG_DIR."
            continue
        fi

        if ! cd "$LOG_DIR"; then
            echo "Error changing directory to $LOG_DIR. Skipping."
            continue
        fi

        find . -type f \( -name "*.log" -o -name "*.log.*" \) -mtime +$MAX_AGE -exec rm {} \;
        find . -type f -name "*.gz" -mtime +$MIN_AGE -exec rm {} \;


        echo "Log cleaning completed for $LOG_DIR."
    fi
done

# Process 2**
echo "Disk usage of /var/cache/apt before cleanup:"
du -sh /var/cache/apt
apt autoclean

echo "Journal disk usage before vacuuming:"
journalctl --disk-usage
journalctl --vacuum-time=3d

#process 3 
if command -v docker &> /dev/null; then
    echo "Docker is installed on the system."

    echo "Docker elements disk usage (Before pruning):"
    du -sh /var/lib/docker/*

    docker system prune -a -f
    echo "Docker elements disk usage (After pruning):"
    du -sh /var/lib/docker/*

 else
 echo "Docker is not installed on the system. Skipping Docker cleanup."
fi

after_cleanup_size=$(df -h --output=avail / | awk 'NR==2 {print $1}' | numfmt --from=auto)

total_cleaned_size_tmp=$((after_cleanup_size - before_cleanup_size))

total_cleaned_size=$(echo "scale=2; $total_cleaned_size_tmp / (1024 * 1024)" | bc)


#echo "Total cleaned disk size: $total_cleaned_size_formatted $unit"

echo " "

echo "------------------------------------------------------------------"
echo "Total cleaned disk size: $total_cleaned_size"
echo " "

echo "we are done ! 💣"
echo "  "
