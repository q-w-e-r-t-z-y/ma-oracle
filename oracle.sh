#!/bin/bash

CWD=$(dirname "$0")
ORACLE="/lab/oracle"

function check_oracle () {
    local value_directory_file_data_oracle="$1"
    local in_oracle=0
    printf ">>> Checking oracle... "
    if [ -d "$value_directory_file_data_oracle" ]; then
        in_oracle=1
    fi
    return $in_oracle
}

function get_oracle () {
    local value_directory_file_data_oracle="$1"
    local value_file_data="$2"
    printf ">>> Querying oracle details...\n"
    cat "$value_directory_file_data_oracle"/"$value_file_data"
    printf "\n"
    tree "$value_directory_file_data_oracle"
}

function get_file_details () {
    local value_file="$1"
    local value_directory_file_data_oracle="$2"
    local value_file_data="$3"
    local signature_file="$value_directory_file_data_oracle/$value_file_data"
    printf "REPORT TIMESTAMP                : $(date +"%d/%m/%Y %H:%M:%S")\n" >> "$signature_file"
    printf "FILE                            : " >> "$signature_file"
    file --brief --preserve-date "$value_file" >> "$signature_file"
    printf "MAGIC (HEX 32)                  : " >> "$signature_file"
    if [[ $(xxd -p -g4 -l4 "$value_file" ) ]]; then printf "0x$(xxd -p -g4 -l4 "$value_file")\n"; else printf "\n"; fi >> "$signature_file"
    printf "SHA256                          : " >> "$signature_file"
    sha256sum "$value_file" | cut -d " " -f1 >> "$signature_file"
    printf "SSDEEP                          : " >> "$signature_file"
    ssdeep -b -s "$value_file" | tail -n +2 >> "$signature_file"
    exiftool -a -d "%Y-%m-%d %H:%M:%S" "$value_file" | sed '/^ExifTool Version Number/d; /^File Permissions/d; /^File Access Date\/Time/d; /^File Inode Change Date\/Time/d; /^Directory/d; /^Error/d' >> "$signature_file"
}

function process_queue () {
    local value_directory_queue="$1"
    printf ">>> Processing queue...\n"
    find "$value_directory_queue" -type f -name '*' -print0 |
    while IFS= read -r -d '' file; do
        main "--file" "$file"
    done
}

function process_file_type () {
    local value_file_type="$1"
    local value_directory_file_data_oracle="$2"
    local value_file="$3"
    local value_directory_file_data_decompress="$value_directory_file_data_oracle/decompressed"
    case "$value_file_type" in
        *"archive data"*|*compressed*)
            mkdir -p "$value_directory_file_data_decompress"
            case "$value_file_type" in
                zip*|Zip*|ZIP*)
                    unzip -q -d "$value_directory_file_data_decompress" -j -n "$value_file"
                    process_queue "$value_directory_file_data_decompress"
                ;;
                rar*|Rar*|RAR*)
                    unrar e -inul -y "$value_file" "$value_directory_file_data_decompress"
                    process_queue "$value_directory_file_data_decompress"
                ;;
                7-zip*|7-Zip*|7-ZIP*)
                    7za e -o"$value_directory_file_data_decompress" -y "$value_file"
                    process_queue "$value_directory_file_data_decompress"
                ;;
                *)
                    printf "///\n/// Unsuported file format, please update...\n///\n"
                ;;
            esac
        ;;
    esac
}



function main () {
    local value_action="$1"
    local value_parameter="$2"
    case $value_action in
        "--file")
            local file_type=$(file --brief "$value_parameter")
            if ! [[ "$file_type" == *"directory"* ]] ; then
                local file_sha=$(sha256sum "$value_parameter" | cut -d " " -f1)
                local directory_file_data_oracle="$ORACLE/$file_sha"
                local file_data=".$file_sha-report.txt"
                local file_name=$(basename -- "$value_parameter")
                check_oracle "$directory_file_data_oracle"
                local in_oracle="$?"
                if [ $in_oracle -eq 0 ] ; then
                    printf "Not found\n"
                    mkdir -p "$directory_file_data_oracle"
                    cp -u "$value_parameter" "$directory_file_data_oracle"
                    printf "* File    : $file_name\n"
                    printf "* Type    : $file_type\n"
                    printf "* SHA-256 : $file_sha\n"
                    printf "* STAGE 1 : Collecting file signatures...\n"
                    get_file_details "$value_parameter" "$directory_file_data_oracle" "$file_data"
                    printf "* STAGE 2 : Adding to oracle...\n"
                    process_file_type "$file_type" "$directory_file_data_oracle" "$value_parameter"
                else
                    printf "Found\n"
                    get_oracle "$directory_file_data_oracle" "$file_data"
                fi
            else
                printf "[ $file_type ] : Type not supported, exiting...\n"
            fi
        ;;
        "--list")
            if [[ "$value_parameter" == "all" ]] ; then
                printf ">>> Listing oracle entries...\n"
                tree "$ORACLE"
            else
                printf ">>> Listing oracle entry \"$value_parameter\"...\n"
                tree "$ORACLE"/"$value_parameter"
            fi
        ;;
        "--search")
            printf ">>> Searching oracle for \"$value_parameter\"...\n"
            find "$ORACLE" -iname "*$value_parameter*" -exec dirname {} \; | sort | uniq | xargs -I@ tree --noreport @
        ;;
        "--report")
            printf ">>> Showing report information for \"$value_parameter\"...\n"
            cat "$ORACLE"/"$value_parameter"/".$value_parameter-report.txt"
        ;;
        "--mods")
            if [[ "$value_parameter" == "all" ]] ; then
                printf ">>> Listing of all modifications (ordered descending by date/time) in oracle...\n"
                find "$ORACLE"/ -printf '%T@ %Td-%Tm-%TY %TH:%TM:%.2TS %p\n' | sort -rn | cut -f2- -d" "
            elif [[ "$value_parameter" == "last" ]] ; then
                printf ">>> Last modification in oracle...\n"
                find "$ORACLE"/ -printf '%T@ %Td-%Tm-%TY %TH:%TM:%.2TS %p\n' | sort -rn | head -1 | cut -f2- -d" "
            else
                printf ">>> Listing of modifications (ordered descending by date/time) in entry \"$value_parameter\"...\n"
                find "$ORACLE"/"$value_parameter"/ -printf '%T@ %Td-%Tm-%TY %TH:%TM:%.2TS %p\n' | sort -rn | cut -f2- -d" "
            fi
        ;;
        "--size")
            if [[ "$value_parameter" == "all" ]] ; then
                printf ">>> Disk usage for all oracle entries...\n"
                du -hc "$ORACLE"/* | sort -rh
            else
                printf ">>> Disk usage for entry \"$value_parameter\"...\n"
                du -hc "$ORACLE"/"$value_parameter" | sort -rh
            fi
        ;;
        "--delete")
            printf ">>> Deleting entry $value_parameter...\n"
            if [ -d "$ORACLE/$value_parameter" ]; then
                while true; do
                    read -p "Are you sure? (This action is irreversible!) " yn
                    case $yn in
                        [Yy]* ) 
                            rm -rfv "$ORACLE"/"$value_parameter"
                            break
                        ;;
                        [Nn]* )
                            printf "\n" 
                            exit
                        ;;
                        * ) 
                            printf "Please answer [Y] yes or [N] no\n\n"
                        ;;
                    esac
                done
            else
                printf "Entry was not found in oracle, exiting...\n"
            fi
        ;;
        *)
            printf "$0 *** ERROR: - Undefined action: \"$value_action\", exiting...\n" 
        ;;
    esac
}

action="$1"
parameter="$2"

if [[ "$#" -ne 2  ]]; then
    printf "\n$0 *** ERROR: - List of parameters:\n"
    printf "    --file    [NAME]    : Process file NAME\n"
    printf "    --list    [ALL]     : List ALL oracle entries\n"
    printf "    --list    [SHA-256] : List entry with SHA-256\n"
    printf "    --search  [VALUE]   : Search for VALUE in oracle\n"
    printf "    --report  [SHA-256] : Show report information for entry with SHA-256\n"
    printf "    --mods    [ALL]     : Print a list of ALL locations/files where modifications (ordered descending by date/time) occured\n"
    printf "    --mods    [LAST]    : Print the location/file where the LAST modification occured in oracle\n"
    printf "    --mods    [SHA-256] : Print a list of locations/files where modifications occured in entry with SHA-256 (ordered descending by date/time)\n"
    printf "    --size    [ALL]     : Print disk size used by ALL oracle entries\n"
    printf "    --size    [SHA-256] : Print disk size used by entry SHA-256\n"
    printf "    --delete  [SHA-256] : Delete entry with SHA-256\n\n"
    exit 1
else
    printf "\n"
    main "$action" "$parameter" 
    printf "\n"
fi