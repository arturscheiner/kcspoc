#!/bin/bash

cmd_logs() {
    local ACTION=""
    local TARGET=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                ACTION="list"
                TARGET="$2"
                shift 2
                ;;
            --show)
                ACTION="show"
                TARGET="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: kcspoc logs --list [command] | --show [hash]"
                return 1
                ;;
        esac
    done

    ui_banner

    if [ "$ACTION" == "list" ]; then
        if [ -z "$TARGET" ]; then
            echo -e "${RED}Error: Command name required for --list (e.g., --list prepare)${NC}"
            return 1
        fi
        
        local log_dir="$LOGS_DIR/$TARGET"
        if [ ! -d "$log_dir" ]; then
            echo -e "${YELLOW}No logs found for command: $TARGET${NC}"
            return 0
        fi
        
        ui_section "Logs for '$TARGET'"
        printf "   ${BOLD}%-20s %-10s %-15s %-10s${NC}\n" "DATE/TIME" "HASH" "STATUS" "VERSION"
        printf "   ${DIM}%s${NC}\n" "---------------------------------------------------------"

        # List last 10 logs, sorted by reverse name (descending timestamp)
        local count=0
        ls -r "$log_dir"/*.log 2>/dev/null | head -n 10 | while read -r log_file; do
            local filename=$(basename "$log_file")
            # Filename: YYYYMMDD-HHMMSS-HASH.log
            local date_part=$(echo "$filename" | cut -d'-' -f1)
            local time_part=$(echo "$filename" | cut -d'-' -f2)
            local hash_part=$(echo "$filename" | cut -d'-' -f3 | cut -d'.' -f1)
            
            # Extract info from file content
            local status=$(grep "EXECUTION FINISHED:" "$log_file" | awk '{print $4}' || echo "UNKNOWN")
            local version=$(grep "Version:" "$log_file" | head -n1 | awk '{print $2}' || echo "?")
            
            local fmt_date="${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${time_part:0:2}:${time_part:2:2}"
            
            local color=$RED
            if [ "$status" == "SUCCESS" ]; then color=$GREEN; 
            elif [ "$status" == "UNKNOWN" ]; then color=$DIM; fi

            printf "   %-20s %-10s ${color}%-15s${NC} %-10s\n" "$fmt_date" "$hash_part" "$status" "$version"
        done
        echo ""

    elif [ "$ACTION" == "show" ]; then
        if [ -z "$TARGET" ]; then
            echo -e "${RED}Error: Hash required for --show (e.g., --show A1B2C3)${NC}"
            return 1
        fi
        
        # Find file by hash (recursive grep in logs dir is risky if multiple commands share hash, but unlikely with 6 chars. 
        # Safer to find name *HASH.log
        local log_file=$(find "$LOGS_DIR" -name "*${TARGET}.log" | head -n 1)
        
        if [ -z "$log_file" ]; then
            echo -e "${RED}Log with hash '$TARGET' not found.${NC}"
            return 1
        fi
        
        ui_section "Log Content: $TARGET"
        echo -e "${DIM}File: $log_file${NC}\n"
        # Check if less allows colors (-R), otherwise cat
        if command -v less &>/dev/null; then
            less -R "$log_file"
        else
            cat "$log_file"
        fi
    else
        echo -e "${YELLOW}Usage: kcspoc logs --list [command] | --show [hash]${NC}"
    fi
}
