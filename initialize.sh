#!/bin/bash
############################################################################
# script name: main_workflow.sh
############################################################################
# version history
# date          author          description
# 04132025      pbelefante      created initial script
# 04142025      pbelefante      finalized script

# script overview
# This script is for the initialization of the 'bootcamp_hw1' database.
# This script utilizes the setup functions
# initialize_cust_tables and initialize_om_tables.
# All data will be deleted if this script is ran.
############################################################################

# Get Main Directory
MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MAIN

# Get Directories from dir.conf
source "${MAIN}/scripts/conf/dir.conf"

# Import Configs
source "${CONF}/pg_env.conf"
source "${CONF}/log.conf"

# Import Main Functions
source "${FUNC}/common_func.sh"

# Import Setup Functions
source "${SETUP}/initialize_cust_tables.sh"
source "${SETUP}/initialize_om_tables.sh"

initialize_db()
{
    local me=initialize_db


    cfu_log "${me}" "WARNING: This script will initialize the 'BOOTCAMP_HW1' database."
    cfu_log "${me}" "WARNING: Running this script will DELETE ALL OF YOUR DATA."
    cfu_log "${me}" "WARNING: If you want to continue, please type YES (in all uppercase)."
    cfu_log "${me}" "WARNING: Any other input will abort the process."

    read -p "Answer: " answer

    if [[ "${answer}" == "YES" ]]
    then
        cfu_log "${me}" "Performing Database Initialization."

        PG_DB_PASSWORD=$(cat "${SEC}/pg_password.sec")

        # Drop the database if it exists; exit if this step fails.
        if ! PGPASSWORD="${PG_DB_PASSWORD}" sudo -u postgres psql -c "DROP DATABASE IF EXISTS bootcamp_hw1;" >/dev/null 2>&1
        then
            cfu_log "${me}" "ERROR: Failed to drop database bootcamp_hw1."
            exit 1
        fi

        # Create the new database; exit if this step fails.
        if ! PGPASSWORD="${PG_DB_PASSWORD}" sudo -u postgres psql -c "CREATE DATABASE bootcamp_hw1;" >/dev/null 2>&1
        then
            cfu_log "${me}" "ERROR: Failed to create database bootcamp_hw1."
            exit 1
        fi

        # Initialize customer tables; exit if this step fails.
        if ! initialize_cust_tables
        then
            cfu_log "${me}" "ERROR: Failed to initialize customer tables."
            exit 1
        fi

        # Initialize OM tables; exit if this step fails.
        if ! initialize_om_tables
        then
            cfu_log "${me}" "ERROR: Failed to initialize OM tables."
            exit 1
        fi

        cfu_log "${me}" "Database initialization finished successfully."
    fi

}

initialize_db

cfu_log "INITIALIZE_DB" "Performing cleanup of irrelevant files."

for file in "${LOGS}"/*
do
    if [[ -f "${file}" && ! -s "${file}" ]]
    then
        rm -f "${file}" 2>/dev/null
    fi
done

cfu_log "INITIALIZE_DB" "Overall Processes Finished."

