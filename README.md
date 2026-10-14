# Student Attendance Tracker Deployment Agent

## Overview
This project is a Bash deployment agent that helps users deploy, run, and archive logs for a Python student attendance tracker.

## Requirements
- Bash
- Python 3
- zip
- Standard Linux utilities such as sed, cp, chmod, and date

## How to Run
From the repository directory, execute:

```bash
bash deploy_agent.sh
```

The interactive menu provides three main features:

1. Deploy application
2. Run application
3. Archive logs
4. Exit

## Deployment
The deployment agent checks that Python 3 and zip are installed. It asks for a project name and creates an `attendance_tracker_<name>` directory.

If the directory already exists, the user can confirm whether to overwrite it or cancel deployment.

The deployed project includes:
- `attendance_checker.py` — the attendance application copied from the template.
- `Helpers/config.json` — configuration file.
- `Helpers/assets.csv` — student roster.
- `reports/` — attendance and absence logs.
- `archives/` — archived log files.

The roster can be copied from the template with existing attendance counts, or generated with zero attendance and absence counts.

The application file is made executable, and the configuration file is restricted to its owner with permission `600`.

## Thresholds
During deployment, the user can choose whether to update the warning and failure thresholds. The default values are 75 and 50. Custom values must be whole numbers from 0 to 100.

## Running the Application
Choose option 2 and enter the name of an existing deployed project. The agent runs the Python attendance application from that project's directory.

A successful deployment automatically starts the attendance application.

## Archiving Logs
Choose option 3 and enter the deployed project name. Existing logs are copied into timestamped archive directories:

- `archives/attendance/attendance_YYYYMMDD_HHMMSS.log`
- `archives/absent/absent_YYYYMMDD_HHMMSS.log`

If a log file does not exist, the agent reports that it was not found.

## Interrupt Handling
During deployment, pressing Ctrl+C (SIGINT) or Ctrl+Z (SIGTSTP) should trigger the deployment interrupt handler. The handler attempts to archive the incomplete project as `attendance_tracker_<name>_archive.zip`. If archiving succeeds, the incomplete directory is removed; if archiving fails, the directory is kept.

Interrupt handling is intended for deployment only and should not interrupt an attendance-marking session.

## Testing
The script syntax can be checked with:

```bash
bash -n deploy_agent.sh
```

Test deployment with both roster options, default and custom thresholds, running an existing project, archiving existing and missing logs, and interrupting a deployment to inspect the resulting ZIP archive.

## Repository Structure
```text
deploy_agent_Belinda-34/
├── deploy_agent.sh
├── README.md
└── templates/
    ├── attendance_checker.py
    ├── config.json
    └── assets.csv
```

The Python application templates are copied into deployed projects without modification.


## Video Walkthrough
[Watch the project demonstration](https://drive.google.com/file/d/1TxFZ4htZ_cEb_0YFqn_XwbawOMkA-Iuw/view?usp=sharing)
