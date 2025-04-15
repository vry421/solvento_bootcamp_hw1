#!/bin/bash
############################################################################
# script name: get_businessdate.sh
############################################################################
# version history
# date          author          description
# 04082025      pbelefante      created initial script
# 04142025      pbelefante      finalize script
#
# script overview
# This script defines the function 'get_businessdate', which
# returns the businessdate in the format YYYY-MM-DD
############################################################################


get_businessdate()
{
    local me=get_businessdate

    # -------------------------------------------------------------------------------------
    # NOTE: "SELECT process_date FROM om_businessdate;" will return the following:
    #
    #
    #  process_date
    # ---------------
    #  YYYY-MM-DD
    #
    #
    # What we only need is the YYYY-MM-DD output at Line 3, so we perform the following:
    #
    # sed --> read and edit text line by line
    # -n  --> suppress output of sed (as sed prints every line)
    # 3p  --> print only line 3
    #
    #
    # Another issue is that in the cli output of psql, a whitespace is added at the
    # beginning, so we process the output again.
    #
    # We will be using xargs, which defaults into the echo command when no input is
    # provided. When a text with leading and trailing whitespaces are sent into
    # xargs with no input arguments, these whitespaces will be removed.
    # -------------------------------------------------------------------------------------

    local initial_output

    initial_output=$(cfu_exec_postgres_query "SELECT process_date FROM om_businessdate;" 'verbose')
    if [[ $? -ne 0 ]]
    then
        cfu_log "${me}" "Failed to retrieve businessdate from OM_BUSINESSDATE."
        return 1
    fi

    local businessdate
    businessdate=$(echo "${initial_output}" | sed -n 3p | xargs)
    echo "${businessdate}"
}


