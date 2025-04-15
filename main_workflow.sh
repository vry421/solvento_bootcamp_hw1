#!/bin/bash
############################################################################
# script name: main_workflow.sh
############################################################################
# version history
# date          author          description
# 04122025      pbelefante      create initial script
# 04142025      pbelefante      finalize script

# script overview
# This script defines the main workflow, where data from CSV files are
# processed and loaded into the PostgreSQL database, while
# taking note of task status through the om tables.
############################################################################

# Get Main Directory
MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MAIN

# Get Directories from dir.conf
source "${MAIN}/scripts/conf/dir.conf"

# Import Configs
source "${CONF}/pg_env.conf"
source "${CONF}/line.conf"
source "${CONF}/log.conf"

# Import Main Functions
source "${FUNC}/common_func.sh"
source "${FUNC}/get_businessdate.sh"
source "${FUNC}/set_businessdate.sh"
source "${FUNC}/talend_func.sh"
source "${FUNC}/run_talend_pipeline.sh"


main_workflow()
{
    local me=main

    # Initialize Temporary Folder
    if [[ -d "${TEMP}" ]]
    then
        rm -rf "${TEMP}" 2>/dev/null
    fi

    mkdir -p "${TEMP}"


    # ============================================================================================
    # 1. Introduction
    echo ${LINE1}

    cfu_log "${me}" "This is a workflow designed by Paul Bryan Elefante"
    cfu_log "${me}" "to be submitted to Solvento Philippines Inc."
    cfu_log "${me}" "as a requirement for the Data Management Bootcamp 2025."

    echo ${LINE2}
    cfu_log "${me}" "Will now execute a perform an operation to call a"
    cfu_log "${me}" "Talend script for an ETL process."

    # ============================================================================================



    # ============================================================================================
    # 2. Create Backups for Customer Tables In Case of Talend Errors
    echo ${LINE2}

    cfu_log "${me}" "Creating backups for customer tables."
    cfu_log "${me}" "Table rollback will be performed in case of errors."

    cfu_backup_table "customer_info" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
    cfu_backup_table "customer_address" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
    cfu_backup_table "customer_dim" || { cfu_log "${me}" "${default_error_notif}"; return 1; }

    # ============================================================================================


    # ============================================================================================
    # 3: Retrieve Businessdate
    echo ${LINE2}

    cfu_log "${me}" "Retrieving latest business date from table 'OM_BUSINESSDATE'."
    current_date=$(get_businessdate)

    # NOTE: For Simulation purposes only ----------------------------------------------

    if [[ "${current_date}" == "(0 rows)" ]]
    then
        current_date="2025-04-01"
        cfu_exec_postgres_query "INSERT INTO om_businessdate VALUES ('${current_date}');" >/dev/null 2>&1
    fi

    # ---------------------------------------------------------------------------------

    cfu_log "${me}" "Current Business Date: ${current_date}."

    # ============================================================================================


    # ============================================================================================
    # 4.1: Run Talend Pipeline
    echo ${LINE2}

    cfu_log "${me}" "Will now run Talend pipeline."

    start_time_talend=$(date '+%Y-%m-%d %H:%M:%S')

    run_talend_pipeline "${current_date}"
    exit_code=$?

    end_time_talend=$(date '+%Y-%m-%d %H:%M:%S')

    cfu_log "${me}" "Talend processes finished."
    # ------------------------------------------------------------------------------
    # 4.2: Check if Talend Run is Successful

    local record=0

    if [[ ${exit_code} -ne 0 ]]
    then
        cfu_log "${me}" "Errors Detected. Table rollback will be performed to latest backup."
        cfu_restore_table "customer_info" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        cfu_restore_table "customer_address" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        cfu_restore_table "customer_dim" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        local task_status="failed"
    else
        while IFS= read -r count
        do
            ((record += count))
        done < "${TEMP}/record.log"
    
        local task_status="success"
    fi

    # ============================================================================================


    # ============================================================================================
    # 5: Update OM_TASK_RUN
    echo ${LINE2}

    cfu_log "${me}" "Total number of records modified or added: ${record}."
    cfu_log "${me}" "Will now update table 'OM_TASK_RUN'."

    if ! cfu_update_om_task_run "om_talend" "${current_date}" \
        "${task_status}" "${record}" \
        "${start_time_talend}" "${end_time_talend}"
    then
        cfu_log "${me}" "OM_TASK_RUN update failed. Performing rollback..."
        
        cfu_restore_table "customer_info" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        cfu_restore_table "customer_address" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        cfu_restore_table "customer_dim" || { cfu_log "${me}" "${default_error_notif}"; return 1; }

        cfu_log "${me}" "${default_error_notif}"
        return 1
    fi

    cfu_log "${me}" "'OM_TASK_RUN' update process finished."

    # ============================================================================================


    # ============================================================================================
    # 6. Update OM_BUSINESSDATE
    echo ${LINE2}

    cfu_log "${me}" "Will now update businessdate in OM_BUSINESSDATE."

    if ! set_businessdate "${current_date}"
    then
        cfu_log "${me}" "OM_BUSINESSDATE update failed. Performing rollback..."

        cfu_restore_table "customer_info" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        cfu_restore_table "customer_address" || { cfu_log "${me}" "${default_error_notif}"; return 1; }
        cfu_restore_table "customer_dim" || { cfu_log "${me}" "${default_error_notif}"; return 1; }

        cfu_log "${me}" "${default_error_notif}"
        return 1
    fi

    cfu_log "${me}" "'OM_BUSINESSDATE' update process finished."

    # ============================================================================================  


    # ============================================================================================
    # 7. Final Cleanup
    echo ${LINE2}

    cfu_log "${me}" "Main workflow process finished."
    cfu_log "${me}" "Performing cleanup of temporary and irrelevant files."
    
    rm -rf "${TEMP}" 2>/dev/null

    for file in "${LOGS}"/*
    do
        if [[ -f "${file}" && ! -s "${file}" ]]
        then
            rm -f "${file}" 2>/dev/null
        fi
    done
    
    cfu_log "${me}" "Overall Processes Finished."

    echo ${LINE1}
    # ============================================================================================  

}

main_workflow | tee "${log_main_workflow}"




