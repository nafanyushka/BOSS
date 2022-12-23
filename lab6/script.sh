#!/bin/bash

gcc -Wall 2.$1.c
./a.out & pstree | grep a.out
