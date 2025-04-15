#!/bin/bash
############################################################################
# script name: run_talend_pipeline.sh
############################################################################
# version history
# date          author          description
# 04102025      pbelefante      created initial script
# 04112025      pbelefante      added code for running talend scripts
# 04122025      pbelefante      renamed script to run_talend_pipeline.sh;
#                               main workflow is now in a separate script
# 04142025      pbelefante      finalized script

# script overview
# This script defines the talend execution pipeline.
############################################################################

run_talend_pipeline()
{

    local me=talend_execute
    local current_date=$1

    # ============================================================================================
    # 1: Execute Talend Dataloading

    info_file="${DATA}/${current_date}_customerinfo.csv"
    address_file="${DATA}/${current_date}_customeraddress.csv"

    # Check file existence ------------------------------------------------------

    local file_not_exist=0

    if [[ ! -f "${info_file}" ]]
    then
        msg="ERROR: ${info_file} does not exist."
        cfu_log "${me}" "${msg}"
        echo "$(cfu_log "${me}" "${msg}")" >> "${log_error}"
        file_not_exist=1
    fi
  
    if [[ ! -f "${address_file}" ]]
    then
        msg="ERROR: ${address_file} does not exist."
        cfu_log "${me}" "${msg}"
        echo "$(cfu_log "${me}" "${msg}")" >> "${log_error}"
        file_not_exist=1
    fi

    if [[ ${file_not_exist} -eq 1 ]]
    then
        end_time_talend=$(date '+%Y-%m-%d %H:%M:%S')
        cfu_log "${me}" "Stopping the process."

        return 1
    fi

    #----------------------------------------------------------------------------


    cfu_log "${me}" "Executing Talend Scripts."
    cfu_log "${me}" "Will now execute Talend workflow for dataloading on date ${current_date}"
    run_talend_dataloading "${current_date}"
    status_dataloading=$?


    if [[ ${status_dataloading} -ne 0 ]]
    then
        cfu_log "${me}" "Stopping the process."
        return 1
    fi

    # ============================================================================================


    # ============================================================================================
    # 2: Execute Talend ETL

    run_talend_etl "${current_date}"
    status_etl=$?


    if [[ ${status_etl} -ne 0 ]]
    then
        cfu_log "${me}" "Stopping the process."
        return 1
    fi

    # ============================================================================================

}



