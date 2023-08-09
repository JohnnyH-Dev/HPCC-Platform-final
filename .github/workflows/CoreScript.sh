#!/bin/bash

set -x

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
      "$binary" "$corefile" > "$binaryname.trace" 2>&1
done

# check if any trace files are generated
if ls *.trace 1> /dev/null 2>&1; then
    # if yes, zip them
    zip -r trace_files.zip *.trace
else
    # if no, create a txt file stating no trace files detected
    echo "No trace files detected" > trace_files.txt
    zip trace_files.zip trace_files.txt
fi

# remove trace files or the txt file
rm -f *.trace
rm -f trace_files.txt

