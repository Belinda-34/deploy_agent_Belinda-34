#!/bin/bash

set -o pipefail 

check_requirements(){
	if ! command -v python3 >/dev/null 2>&1; then
		echo "Error: python3 is not installed."
		return 1
	fi

	if ! command -v zip >/dev/null 2>&1; then
		echo "Error: zip is not installed."
		return 1
	fi

	echo "Checking Python installation..."
	python3 --version

	echo "Checking zip installatin..."
	zip -v | head -n 2
	
	echo "All tools are installed."
}


handle_deploy_interrupt() {
    echo
    echo "Deployment interrupted!"

    if [[ -d "$project_dir" ]]; then
        if zip -r "${project_dir}_archive.zip" "$project_dir"; then
            echo "Incomplete project archived."
            rm -rf -- "$project_dir"
            echo "Incomplete project directory removed."
        else
            echo "Could not create archive. Keeping the project directory."
        fi
    else
        echo "No project directory exists to archive."
    fi

    trap - INT TSTP
    exit 130
}

deploy_project(){
	echo "---Deploy student attendance tracker---"
       
	read -r -p "Enter a project name: " project_name

	if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		echo "Error: Use only letters, numbers, underscores and hyphens."
		return 1
	fi 

	project_dir="attendance_tracker_${project_name}"

	if [[ -e "$project_dir" ]]; then
		read -r -p "$project_dir already exists.Overwrite? (y/n): " answer

		if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
			echo "Deployment cancelled."
			return 1
		fi 
		
		rm -rf -- "$project_dir"
	fi
	
	trap 'handle_deploy_interrupt' INT TSTP

	mkdir -p "$project_dir/Helpers" "$project_dir/reports" || {
		echo "Error: Could not create project directories."
		return 1 
	}
	cp templates/attendance_checker.py "$project_dir/" || return 1
	cp templates/config.json "$project_dir/Helpers" || return 1

	echo "Project directories created."
	echo "Application and configuration copied."
	build_roster || return 1
	edit_thresholds || return 1

	chmod +x "$project_dir/attendance_checker.py" || return 1
	chmod 600 "$project_dir/Helpers/config.json" || return 1

	echo "File permissions configured."

	trap - INT TSTP

	echo "Deployment successful. Starting the application..."

	cd "$project_dir" || {
		trap - INT TSTP
		return 1
	}
	
	python3 attendance_checker.py
	cd .. || return 1

}



build_roster() {
    echo "Choose a roster option:"
    echo "A. Copy students from the template"
    echo "B. Generate a fresh roster"

    read -r -p "Choose A or B: " choice

    if [[ "$choice" == "A" || "$choice" == "a" ]]; then
        read -r -p "How many students (1-10)? " count

        if [[ ! "$count" =~ ^[0-9]+$ ]] || (( 10#$count < 1 || 10#$count > 10 )); then
            echo "Invalid student count."
            return 1
        fi

        head -n "$((10#$count + 1))" templates/assets.csv > "$project_dir/Helpers/assets.csv" || {
            echo "Error: Could not copy students."
            return 1
        }

        sed -i -E 's/"total_sessions"[[:space:]]*:[[:space:]]*[0-9]+/"total_sessions": 5/' "$project_dir/Helpers/config.json" || return 1

    elif [[ "$choice" == "B" || "$choice" == "b" ]]; then
        read -r -p "How many students (1-10)? " count

        if [[ ! "$count" =~ ^[0-9]+$ ]] || (( 10#$count < 1 || 10#$count > 10 )); then
            echo "Invalid student count."
            return 1
        fi

        head -n 1 templates/assets.csv > "$project_dir/Helpers/assets.csv" || {
            echo "Error: Could not create roster header."
            return 1
        }

        if ! tail -n +2 templates/assets.csv | head -n "$count" |
        while IFS=, read -r email name attendance absence; do
            echo "$email,$name,0,0"
        done >> "$project_dir/Helpers/assets.csv"; then
            echo "Error: Could not create fresh roster."
            return 1
        fi

        sed -i -E 's/"total_sessions"[[:space:]]*:[[:space:]]*[0-9]+/"total_sessions": 1/' "$project_dir/Helpers/config.json" || return 1

    else
        echo "Invalid choice. Please choose A or B."
        return 1
    fi

    echo "Roster created successfully."
}

edit_thresholds() {
    read -r -p "Do you want to update the thresholds? (y/n): " answer

    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo "Keeping the default thresholds."
        return 0
    fi

    read -r -p "Warning threshold (default 75): " warning
    warning=${warning:-75}

    read -r -p "Failure threshold (default 50): " failure
    failure=${failure:-50}

    if [[ "$warning" =~ ^[0-9]+$ && "$failure" =~ ^[0-9]+$ ]] &&
       (( warning <= 100 && failure <= 100 )); then
        sed -i -E "s/(\"warning\"[[:space:]]*:[[:space:]]*)[0-9]+/\1$warning/" "$project_dir/Helpers/config.json" || return 1
        sed -i -E "s/(\"failure\"[[:space:]]*:[[:space:]]*)[0-9]+/\1$failure/" "$project_dir/Helpers/config.json" || return 1
        echo "Thresholds saved successfully."
    else
        echo "Invalid input. Enter whole numbers from 0 to 100."
        return 1
    fi
}

run_project() {
    read -r -p "Enter the project name to run: " project_name

    project_dir="attendance_tracker_${project_name}"

    if [[ ! -d "$project_dir" ]]; then
        echo "Error: Project not found."
        return 1
    fi

    echo "Running attendance tracker..."
    cd "$project_dir" || return 1
    python3 attendance_checker.py
    cd ..
}

archive_logs() {
    read -r -p "Enter the deployed project name: " project_name
    project_dir="attendance_tracker_${project_name}"

    if [[ ! -d "$project_dir" ]]; then
        echo "Error: Project not found."
        return 1
    fi

    timestamp=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$project_dir/archives/attendance" "$project_dir/archives/absent" || return 1

    if [[ -f "$project_dir/reports/attendance.log" ]]; then
        cp "$project_dir/reports/attendance.log" \
           "$project_dir/archives/attendance/attendance_${timestamp}.log"
        echo "Attendance log archived."
    else
        echo "No attendance log found."
    fi

    if [[ -f "$project_dir/reports/absent.log" ]]; then
        cp "$project_dir/reports/absent.log" \
           "$project_dir/archives/absent/absent_${timestamp}.log"
        echo "Absence log archived."
    else
        echo "No absence log found."
    fi
}


main_menu() {
    while true; do
        echo
        echo "===== ATTENDANCE TRACKER ====="
        echo "1. Deploy application"
        echo "2. Run application"
        echo "3. Archive logs"
        echo "4. Exit"

        read -r -p "Choose an option (1-4): " choice

        case "$choice" in
            1)
                check_requirements && deploy_project
                ;;
            2)
                run_project
                ;;
            3)
                archive_logs
                ;;
            4)
                echo "Goodbye!"
                break
                ;;
            *)
                echo "Invalid choice. Please choose 1-4."
                ;;
        esac
    done
}

main_menu

