#!/bin/bash
############################################################################
# script name: talend_func.sh
############################################################################
# version history
# date          author          description
# 04112025      pbelefante      created initial script
# 04122025      pbelefante      renamed script to talend_func.sh
# 04132025      pbelefante      removed reliance on windows directory
# 04142025      pbelefante      finalized script

# script overview
# This script defines the function for running the talend scripts.
############################################################################


run_talend_dataloading()
{
    local me=run_talend_dataloading

    local process_date=$1
    local log_error="${LOGS}/error__${logdate}.log" # Redefine log_error with two underscores due to weird bash outputs
    
    cfu_log "${me}" "Performing Data Loading."

    bash "${TALEND}/dataloading/dataloading/dataloading_run.sh" \
        --context_param host="${PG_DB_HOST}" \
        --context_param data_folder="${DATA}" \
        --context_param process_date="${process_date}" \
        2>>"${log_error}" \
    | tee "${log_talend_dataloading}" \
    | while IFS= read -r line; do
        {
            cfu_log "${me}" "${line}"
        } done

    local ret_cd=${PIPESTATUS[0]}

    if [[ ${ret_cd} -ne 0 ]]
    then
        cfu_log "${me}" "ERROR: dataloading_run.sh failed. Please see ${log_error} for more details."
        return 1
    fi

}

run_talend_etl()
{
    local me=run_talend_etl
    local process_date=$1

    local log_error="${LOGS}/error__${logdate}.log" # Redefine log_error with two underscores due to weird bash outputs
    cfu_log "${me}" "Performing ETL Process."

    local mod_flag=0
    bash "${TALEND}/main_etl/main/main_run.sh" \
        --context_param host="${PG_DB_HOST}" \
        --context_param process_date="${process_date}" \
        2>>"${log_error}" \
    | tee "${log_talend_etl}" \
    | while IFS= read -r line; do
        {
            if [[ "${line}" == "--START: MODIFICATION LOGS--" ]]
            then
                mod_flag=1
                continue
            
            elif [[ "${line}" == "--END: MODIFICATION LOGS--" ]]
            then
                mod_flag=0
                continue
            fi

            if [[ ${mod_flag} -eq 0 ]]
            then
                cfu_log "${me}" "${line}"
            else
                action=$(echo "${line}" | awk -F'|' '{print $12}')
                count=$(echo "${line}" | awk -F'|' '{print $13}')
                echo "${count}" >> "${TEMP}/record.log"

                if [[ "${action}" == "Inserting" ]]
                then
                    cfu_log "${me}" "Number of Records Inserted: ${count}"

                elif [[ "${action}" == "Updating_Information" ]]
                then
                    cfu_log "${me}" "Number of Records with Information Change Updated: ${count}"

                elif [[ "${action}" == "Updating_Status" ]]
                then
                    cfu_log "${me}" "Number of Records with Status Change Updated: ${count}"
                fi 
            fi
        } done
    

    local ret_cd=${PIPESTATUS[0]}

    if [[ ${ret_cd} -ne 0 ]]
    then
        cfu_log "${me}" "ERROR: main_run.sh failed. Please see ${log_error} for more details."
        return 1
    fi

}





