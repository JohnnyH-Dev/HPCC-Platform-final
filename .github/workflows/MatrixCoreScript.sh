#!/bin/bash

set -x

# gather the engine and pattern information from the environment
engine=$ENGINE
pattern=$PATTERN

# remove '*' character from pattern
pattern=${pattern//\*/}

# search for core files in the current directory
corefiles=$(find ./ -name "core_*")

for corefile in $corefiles; do
  
  # extract binary name
  binaryname=${corefile#*_}
  binaryname=${binaryname%%.*}
  
  # find the binary
  binary=$binaryname

  if [[ -z $binary ]]; then
    echo "Binary $binaryname not found!"
    continue
  fi

  # use gdb to analyze core file
  gdb --batch --quiet -ex "set interactive-mode off" \
      -ex "echo \nBacktrace for all threads\n==========================" \
      -ex "thread apply all bt" \
      -ex "echo \nRegisters:\n==========================" \
      -ex "info reg" \
      -ex "echo \nDisas:\n==========================" \
      -ex "disas" \
      -ex "quit" \
      "$binary" "$corefile" > "${engine}_${pattern}_$binaryname.trace" 2>&1
done

# create a zip file for each engine-pattern pair
zip_file_name="${engine}_${pattern}_trace_files.zip"

# check if any trace files are generated
if ls *${engine}_${pattern}*.trace 1> /dev/null 2>&1; then
    # if yes, zip them
    zip -r $zip_file_name *${engine}_${pattern}*.trace
else
    # if no, create a txt file stating no trace files detected
    echo "No trace files detected" > "${engine}_${pattern}_trace_files.txt"
    zip $zip_file_name "${engine}_${pattern}_trace_files.txt"
fi

