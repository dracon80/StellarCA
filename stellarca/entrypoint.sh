#!/bin/sh

if [ "$1" = 'stellar' ]; then
    #The stellarca command has been executed. Extract the remaining parameters
   stellar init
   stellar gencrl
   stellar ocsp

   exit 0
fi

#Another command is being exec in the container
exec "$@"