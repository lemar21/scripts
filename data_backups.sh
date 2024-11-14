#!/bin/bash

# Prompt for CB1 or CB2 environment
echo "Please choose the environment:"
echo "1) CB1 (paths in /mnt/data)"
echo "2) CB2 (paths in /data)"
read -p "Enter your choice (1 or 2): " ENV_CHOICE

# Define source directories and backup directories for each environment
if [ "$ENV_CHOICE" == "1" ]; then
    # CB1 environment
    echo "Detected CB1 environment"
    SOURCE_DIR_RECORD="/mnt/data/ABLE2/record"
    SOURCE_DIR_LOGS="/mnt/data/log"
    SOURCE_DIR_VIDEO="/mnt/data/ABLE2/video_data"
    BACKUP_DIR_BASE_RECORD_VIDEO="/mnt/data/ABLE2"
    BACKUP_DIR_BASE_LOGS="/mnt/data/log"
elif [ "$ENV_CHOICE" == "2" ]; then
    # CB2 environment
    echo "Detected CB2 environment"
    SOURCE_DIR_RECORD="/data/ABLE2/record"
    SOURCE_DIR_LOGS="/data/log"
    SOURCE_DIR_VIDEO="/data/ABLE2/video_data"
    BACKUP_DIR_BASE_RECORD_VIDEO="/data/ABLE2"
    BACKUP_DIR_BASE_LOGS="/data/log"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Create a human-readable timestamp for the backup directories
TIMESTAMP=$(date +"%B %d, %Y at %I:%M:%S %p")

# Define backup directories for all source directories
BACKUP_DIR_RECORD="$BACKUP_DIR_BASE_RECORD_VIDEO/record_backup_$TIMESTAMP"
BACKUP_DIR_LOGS="$BACKUP_DIR_BASE_LOGS/logs_backup_$TIMESTAMP"
BACKUP_DIR_VIDEO="$BACKUP_DIR_BASE_RECORD_VIDEO/video_data_backup_$TIMESTAMP"

# Debugging output to check if directories are being set correctly
echo "Creating backup directories with timestamp: $TIMESTAMP"
echo "Backup directory for record: $BACKUP_DIR_RECORD"
echo "Backup directory for logs: $BACKUP_DIR_LOGS"
echo "Backup directory for video: $BACKUP_DIR_VIDEO"

# Create the backup directories
echo "Creating backup directory for record at $BACKUP_DIR_RECORD..."
mkdir -p "$BACKUP_DIR_RECORD"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create record backup directory."
    exit 1
fi

echo "Creating backup directory for logs at $BACKUP_DIR_LOGS..."
mkdir -p "$BACKUP_DIR_LOGS"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create logs backup directory."
    exit 1
fi

echo "Creating backup directory for video_data at $BACKUP_DIR_VIDEO..."
mkdir -p "$BACKUP_DIR_VIDEO"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create video data backup directory."
    exit 1
fi

# Check if the source directories exist
if [ ! -d "$SOURCE_DIR_RECORD" ]; then
    echo "Source directory $SOURCE_DIR_RECORD does not exist. Exiting."
    exit 1
fi

if [ ! -d "$SOURCE_DIR_LOGS" ]; then
    echo "Source directory $SOURCE_DIR_LOGS does not exist. Exiting."
    exit 1
fi

if [ ! -d "$SOURCE_DIR_VIDEO" ]; then
    echo "Source directory $SOURCE_DIR_VIDEO does not exist. Exiting."
    exit 1
fi

# Backing up files from the source directories to the backup directory
echo "Backing up files from $SOURCE_DIR_RECORD to $BACKUP_DIR_RECORD..."
if [ "$(ls -A $SOURCE_DIR_RECORD)" ]; then
    mv "$SOURCE_DIR_RECORD"/* "$BACKUP_DIR_RECORD/"
    echo "Record backup completed."
else
    echo "No files found in $SOURCE_DIR_RECORD to back up."
fi

echo "Backing up files from $SOURCE_DIR_LOGS to $BACKUP_DIR_LOGS..."
if [ "$(ls -A $SOURCE_DIR_LOGS)" ]; then
    # Move only files and folders from /mnt/data/log (CB1) or /data/log (CB2) to the backup directory
    # Exclude the newly created backup directory itself
    find "$SOURCE_DIR_LOGS" -mindepth 1 -maxdepth 1 ! -name "$(basename "$BACKUP_DIR_LOGS")" -exec mv {} "$BACKUP_DIR_LOGS/" \;
    if [ $? -ne 0 ]; then
        echo "Error: Failed to move files from $SOURCE_DIR_LOGS to $BACKUP_DIR_LOGS."
        exit 1
    fi
    echo "Logs backup completed."
else
    echo "No files found in $SOURCE_DIR_LOGS to back up."
fi

echo "Backing up files from $SOURCE_DIR_VIDEO to $BACKUP_DIR_VIDEO..."
if [ "$(ls -A $SOURCE_DIR_VIDEO)" ]; then
    mv "$SOURCE_DIR_VIDEO"/* "$BACKUP_DIR_VIDEO/"
    echo "Video data backup completed."
else
    echo "No files found in $SOURCE_DIR_VIDEO to back up."
fi

# Check if the move operations were successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully."
else
    echo "An error occurred during the backup."
    exit 1
fi

# Initiate a reboot after the backup is completed
echo "Backup completed, initiating system reboot..."

# Check if the script is running as root
if [ "$(id -u)" -eq 0 ]; then
    # No sudo required, execute reboot directly
    reboot
else
    # Use sudo if not running as root (with the password 'q')
    echo "q" | sudo -S reboot
fi

# End of script
echo "Reboot initiated."
