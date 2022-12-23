#!/bin/bash

CNT=`echo -e "$USER$HOME" | tr -d "\n" | wc -c`
echo "$USER $HOME $CNT"
