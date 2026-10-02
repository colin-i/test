#!/bin/bash
# Compile and run the Romanian new resources script

# Check if javac is available
if ! command -v javac &> /dev/null; then
    echo "Error: javac not found. Please install Java."
    exit 1
fi

# Compile
javac -encoding UTF-8 log_missing_ro.java

# Run with current directory as classpath
java -cp . log_missing_ro

# Clean up
rm -f log_missing_ro.class