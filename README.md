# Motivation

This project visualizes trends of open pull requests (PRs) and open issues for GitHub repositories listed in the `repositories.txt` file.

## How it Works

1. **Data Retrieval:** The `retrieve.sh` script retrieves the number of open PRs and issues, saving them into individual CSV files for each repository.
2. **Report Generation:** The `plot_report.py` script creates a graphical report, `combined_metrics_report.png`, from the CSV data.

These steps are executed as part of the `Update Tooling Metrics` GitHub Action, with changes committed back to the repository.