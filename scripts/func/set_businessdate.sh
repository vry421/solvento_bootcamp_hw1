#!/bin/bash
############################################################################
# script name: set_businessdate.sh
############################################################################
# version history
# date          author          description
# 04082025      pbelefante      created initial script
# 04102025      pbelefante      adjusted function to take
#                               current businessdate as input
# 04142025      pbelefante      finalized script
#
# script overview
# This script defines the function 'set_businessdate', which
# changes the process_date in om_businessdate based on
# a specified set of conditions. 
#
# In om_businessdate, the date is named "process_date".
# In om_task_run, the date is named "businessdate".
#
# The conditions are as follows:
#
# CONDITION 1 -> If the status of all tasks in businessdate = process_date
#                is SUCCESS, then update process_date to be equal to
#                one day after the current process_date.
#
# CONDITION 2 -> If there is a status of FAILURE in the tasks where
#                businessdate = process_date, do not perform any
#                updating in om_businessdate and create a log
#                indicating any failed execution.
############################################################################


set_businessdate()
{
    local me=set_businessdate

    # Get current date
    # Input $1 should be current date
    local current_date=$1

    # TO BE DELETED --------------------------------------------
    # local current_date=$(get_businessdate)

    # echo "[${me}] Current Business Date: $current_date"

    # ----------------------------------------------------------

    # NOTE: For explanation of the [ | sed -n 3p | xargs ] pipe on num_failures,
    # please refer to /func/get_businessdate.sh

    local num_failures
    num_failures=$(cfu_exec_postgres_query \
        "SELECT COUNT(*) FROM om_task_run WHERE businessdate = '$current_date' AND STATUS != 'success';" 'verbose' \
        | sed -n 3p | xargs
    )

    # -------------------------------------------------------------------------------------
    # NOTE: In the code for variable "failures", the output format is this:
    #
    #
    #  task_name
    # ---------------
    #  task_one
    # (1 row)
    #
    #
    # We only need the task names (task_one, etc).
    # To remove the first two lines, we perform sed '1,2d'
    # To remove the (1 row), we perform grep -v 'row'
    # -------------------------------------------------------------------------------------

    if [ ${num_failures} -eq 0 ]
    then
        local next_date=$(date -d "${current_date} +1 day" +%F)

        cfu_log "${me}" "Updating business date to '${next_date}'."

        cfu_exec_postgres_query "UPDATE om_businessdate SET process_date = '${next_date}';"

        cfu_log "${me}" "Successfully updated table OM_BUSINESSDATE."

    else
        cfu_log "${me}" "${num_failures} failed tasks observed. Businessdate updates will not be performed."
        
        local failures
        failures=$(cfu_exec_postgres_query \
            "SELECT task_name FROM om_task_run WHERE businessdate = '${current_date}' AND status = 'failed';" 'verbose' \
            | sed '1,2d' | sed '/^$/d' |grep -v "row"
        )

        cfu_log "${me}" "Tasks Failed:"

        i=1
        while IFS= read -r line
        do
            cfu_log "${me}" "(${i}) ${line}"
            ((i++))
        done <<< "${failures}"
    fi

}






