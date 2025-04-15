#!/bin/bash
############################################################################
# script name: initialize_om_tables.sh
############################################################################
# version history
# date          author          description
# 04082025      pbelefante      created initial script
# 04132025      pbelefante      wrapped code inside a function
# 04142025      pbelefante      finalized script

# script overview
# This script defined the function initialize_om_tables,
# which initializes the om_businessdate and om_task_run.

# NOTE:
# Do not run if there is important existing data in the tables.
# Only run when the database is relatively new.
############################################################################

initialize_om_tables()
{
    local me=initialize_om_tables

    cfu_log "${me}" "Dropping existing tables if they exist..."

    # Drop existing tables
    cfu_exec_postgres_query "DROP TABLE IF EXISTS om_businessdate;" || {
        cfu_log "${me}" "ERROR: Failed to drop om_businessdate table."
        return 1
    }

    cfu_exec_postgres_query "DROP TABLE IF EXISTS om_task_run;" || {
        cfu_log "${me}" "ERROR: Failed to drop om_task_run table."
        return 1
    }

    cfu_log "${me}" "Creating om_businessdate table..."
    # Create om_businessdate table
    cfu_exec_postgres_query "
        CREATE TABLE om_businessdate (
            process_date DATE PRIMARY KEY
        );
    " || {
        cfu_log "${me}" "ERROR: Failed to create om_businessdate table."
        return 1
    }

    cfu_log "${me}" "Creating om_task_run table..."
    # Create om_task_run table
    cfu_exec_postgres_query "
        CREATE TABLE om_task_run (
            id SERIAL PRIMARY KEY,
            task_name VARCHAR(100) NOT NULL,
            businessdate DATE NOT NULL,
            status TEXT NOT NULL,
            record INTEGER,
            start_datetime TIMESTAMP NOT NULL,
            end_datetime TIMESTAMP NOT NULL
        );
    " || {
        cfu_log "${me}" "ERROR: Failed to create om_task_run table."
        return 1
    }

    cfu_log "${me}" "OM tables initialized successfully."
}


