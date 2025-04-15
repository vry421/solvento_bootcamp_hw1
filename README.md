
---

# Solvento Data Management Bootcamp 2025
## **Homework 1: Shell Script Automation of PostgreSQL and Talend.**
### Author: Paul Bryan M. Elefante

This project contains shell scripts that automate workflows for PostgreSQL and Talend. There are two main scripts:

1. **`initialize.sh`** - Resets the entire database for initial operations. When ran, the user will first be prompted to answer "YES" to continue.

2. **`main_workflow.sh`** - Executes the Talend tasks within the shell script and updates PostgreSQL tables correspondingly.


## Usage Example

To reset the database:
```bash ./initialize.sh```

To run the main workfow:
```bash ./main_workflow.sh```

## Log Handling

Any logs generated during script runs can be accessed inside the `logs` folder. When errors are observed during runtime, these are stored in a log file with prefix **error**.

## Final Notes

This project was developed by Paul Bryan Elefante as a requirement of the Data Management Bootcamp 2025 hosted by Solvento.

The project can be cloned from GitHub using the following: ```git clone https://github.com/vry421/solvento_bootcamp_hw1.git```

---