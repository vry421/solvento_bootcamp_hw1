#!/bin/bash
############################################################################
# script name: initialize_cust_tables.sh
############################################################################
# version history
# date          author          description
# 04102025      pbelefante      created initial script
# 04112025      pbelefante      adjusted tables to adhere to requirements
# 04132025      pbelefante      wrapped code inside a function
# 04142025      pbelefante      finalized script

# script overview
# This script defines the function initialize_cust_tables,
# which initializes the customer_info, customer_address, and
# customer_dim tables.

# NOTE:
# Do not run if there is important existing data in the tables.
# Only run when the database is relatively new.
############################################################################

initialize_cust_tables()
{
    local me=initialize_cust_tables

    cfu_log "${me}" "Dropping existing tables and sequences if they exist..."

    # Drop existing tables and sequences
    cfu_exec_postgres_query "DROP TABLE IF EXISTS customer_info;" || {
        cfu_log "${me}" "ERROR: Failed to drop customer_info table."
        return 1
    }

    cfu_exec_postgres_query "DROP TABLE IF EXISTS customer_address;" || {
        cfu_log "${me}" "ERROR: Failed to drop customer_address table."
        return 1
    }

    cfu_exec_postgres_query "DROP TABLE IF EXISTS customer_dim;" || {
        cfu_log "${me}" "ERROR: Failed to drop customer_dim table."
        return 1
    }

    cfu_exec_postgres_query "DROP SEQUENCE IF EXISTS customer_sequence;" || {
        cfu_log "${me}" "ERROR: Failed to drop customer_sequence."
        return 1
    }

    cfu_log "${me}" "Creating customer_info table..."

    # Create customer_info table
    cfu_exec_postgres_query "
        CREATE TABLE customer_info (
            cust_id INT,
            name VARCHAR(100) NOT NULL,
            age INT NOT NULL
        );
    " || {
        cfu_log "${me}" "ERROR: Failed to create customer_info table."
        return 1
    }

    cfu_log "${me}" "Creating customer_address table..."

    # Create customer_address table
    cfu_exec_postgres_query "
        CREATE TABLE customer_address (
            cust_id INT,
            house_no VARCHAR(20),
            street VARCHAR(100),
            barangay VARCHAR(100),
            city VARCHAR(100),
            region VARCHAR(100)
        );
    " || {
        cfu_log "${me}" "ERROR: Failed to create customer_address table."
        return 1
    }

    cfu_log "${me}" "Creating customer_dim table and customer_sequence..."

    # Create customer_dim table
    cfu_exec_postgres_query "
        CREATE SEQUENCE customer_sequence
            START WITH 1 INCREMENT BY 1;

        CREATE TABLE customer_dim (
            cust_key INT DEFAULT nextval('customer_sequence') PRIMARY KEY,
            cust_id INT,
            name VARCHAR(100) NOT NULL,
            age INT NOT NULL,
            address TEXT,
            start_date DATE,
            end_date DATE,
            status VARCHAR(100)
        );
    " || {
        cfu_log "${me}" "ERROR: Failed to create customer_dim table or customer_sequence."
        return 1
    }

    cfu_log "${me}" "Customer tables initialized successfully."
}


