#!/bin/bash

cd ~
find . -maxdepth 1 -type f -name "*.txt" | wc -l
