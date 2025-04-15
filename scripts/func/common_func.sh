#!/bin/bash
############################################################################
# script name: common_func.sh
############################################################################
# version history
# date          author          description
# 04082025      pbelefante      created initial script
# 04112025      pbelefante      created cfu_upper and cfu_log
# 04122025      pbelefante      created cfu_backup_table,
#                               cfu_restore_table, and
#                               cfu_update_om_task_run
# 04142025      pbelefante      finalized script     
#
# script overview
# This script is used for handling common functions
#
# function descriptions
# cfu_upper <text> - returns text in uppercase
# cfu_log <tag> <text> - returns the output "[TAG] text"
# cfu_backup_table <table_name> - creates a backup table
# cfu_restore_table <table_name> - restores a table to its backup
# cfu_exec_postgres_query <query> - returns query results for
#                                   psql db "bootcamp_week1"
# cfu_update_om_task_run <task_name> <businessdate> <status>
#                        <record> <start_datetime> <end_datetime>
#                        - updates the om_task_run table based on the
#                          input parameters
############################################################################

# Functions Related to Character Translation
cfu_upper()
{
    local me=cfu_upper
    local text=$*
    echo "${text}" | /usr/bin/tr '[:lower:]' '[:upper:]'
}

# Functions Related to Logging
cfu_log()
{
    local tag=$1
    shift
    local text=$*
    echo "[$(cfu_upper "${tag}")] ${text}"
}


# Functions Related to PostgreSQL
cfu_exec_postgres_query()
{
    local me=cfu_exec_postgres_query
    local PG_DB_PASSWORD=$(cat "${SEC}/pg_password.sec")

    if [ $# -lt 1 ]
    then
        echo "Invalid number of parameters provided."
        echo "Function call should be: cfu_exec_postgres_query 'QUERY' 'MODE'."
        echo "If only query is provided, mode defaults to 'silent'."
        echo "Setting mode to anything other than 'silent' will lead to verbose mode."

        return 1
    fi

    local query="$1"
    local mode="${2:-silent}"

    if [[ "${mode}" == "silent" ]]
    then
        PGPASSWORD="${PG_DB_PASSWORD}" psql \
            -h "${PG_DB_HOST}" \
            -U "${PG_DB_USER}" \
            -d "${PG_DB_NAME}" \
            -c "${query}" >/dev/null 2>${log_error}
    else
        PGPASSWORD="${PG_DB_PASSWORD}" psql \
            -h "${PG_DB_HOST}" \
            -U "${PG_DB_USER}" \
            -d "${PG_DB_NAME}" \
            -c "${query}" 2>${log_error}
    fi
    
    local ret_cd=$?
    if [[ ${ret_cd} -ne 0 ]]
    then
        cfu_log "${me}" "ERROR on PSQL Query!"
    fi

    return ${ret_cd}
}


# Functions for Data Safety
cfu_backup_table()
{
    local me=cfu_backup_table
    local table_name="$1"
    local backup_table="${table_name}_backup"

    local query="
        DROP TABLE IF EXISTS ${backup_table};
        CREATE TABLE ${backup_table} AS TABLE ${table_name};
    "

    cfu_log "${me}" "Creating Backup for $(cfu_upper "${table_name}")."
    cfu_exec_postgres_query "${query}"
    
    if [[ $? -ne 0 ]]
    then
        cfu_log "${me}" "Backup failed for $(cfu_upper "${table_name}")"
        return 1
    fi

    cfu_log "${me}" "Backup Creation Successful for $(cfu_upper "${table_name}")."

}

cfu_restore_table() {
    local me=cfu_restore_table
    local table_name="$1"
    local backup_table="${table_name}_backup"

    local query="
        DROP TABLE IF EXISTS ${table_name};
        CREATE TABLE ${table_name} AS TABLE ${backup_table};
    "

    cfu_log "${me}" "Restoring $(cfu_upper "${table_name}") from backup."
    cfu_exec_postgres_query "${query}"

    if [[ $? -ne 0 ]]
    then
        cfu_log "${me}" "Backup failed for $(cfu_upper "${table_name}")"
        return 1
    fi

    cfu_log "${me}" "Restoration Successful for $(cfu_upper "${table_name}")."
}


# Functions Related to OM Updates
cfu_update_om_task_run()
{
    local me=cfu_update_om_task_run
    local task_name=$1
    local businessdate=$2
    local status=$3
    local record=$4
    local start_datetime=$5
    local end_datetime=$6

    existing_failed=$(cfu_exec_postgres_query "
        SELECT COUNT(*) FROM om_task_run
        WHERE task_name = '${task_name}'
            AND businessdate = '${businessdate}'
            AND status = 'failed'
    " "verbose" | sed -n '3p' | xargs)

    if [[ "${existing_failed}" -ne 0 ]]
    then
        cfu_exec_postgres_query "
            UPDATE om_task_run
            SET
                status = '${status}',
                record = '${record}',
                start_datetime = '${start_datetime}',
                end_datetime = '${end_datetime}'
            WHERE task_name = 'om_talend'
                AND businessdate = '${businessdate}'
                AND status = 'failed'
        " >/dev/null
        if [[ $? -ne 0 ]]
        then
            cfu_log "${me}" "Failed to update om_task_run record."
            return 1
        fi
    else
        cfu_exec_postgres_query "
            INSERT INTO om_task_run (
                task_name,
                businessdate,
                status,
                record,
                start_datetime,
                end_datetime
            ) VALUES (
                '${task_name}',
                '${businessdate}',
                '${status}',
                '${record}',
                '${start_datetime}',
                '${end_datetime}'
            );
        " >/dev/null
        if [[ $? -ne 0 ]]
        then
            cfu_log "${me}" "Failed to insert om_task_run record."
            return 1
        fi
    fi
}





