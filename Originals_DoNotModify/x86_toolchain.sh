#! /bin/bash

# Created by Diego Hernandez
# ISS Program, SADT, SAIT
# March 17/24

#!/bin/bash

# Default settings
VERBOSE=false
BITS=true
POSITIONAL_ARGS=()
GDB=false
OUTPUT_FILE=""
QEMU=false
BREAK="_start"
RUN=false

# Help message function
show_help() {
    echo "Usage:"
    echo ""
    echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
    echo ""
    echo "-v | --verbose                Show some information about steps performed."
    echo "-g | --gdb                    Run gdb command on executable."
    echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
    echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
    echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
    echo "-32| --x86-32                 Compile for 32bit (x86-32) system."
    echo "-o | --output <filename>      Output filename."
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--gdb)
            GDB=true
            shift # past argument
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift # past argument
            shift # past value
            ;;
        -v|--verbose)
            VERBOSE=true
            shift # past argument
            ;;
        -32|--x86-32)
            BITS=false
            shift # past argument
            ;;
        -q|--qemu)
            QEMU=true
            shift # past argument
            ;;
        -r|--run)
            RUN=true
            shift # past argument
            ;;
        -b|--break)
            BREAK="$2"
            shift # past argument
            shift # past value
            ;;
        -*|--*)
            echo "Unknown option $1"
            show_help
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

# Check for required arguments
if [ $# -lt 1 ]; then
    echo "Error: Assembly filename not provided."
    show_help
fi

# Check if the specified file exists
if [ ! -f "$1" ]; then
    echo "Specified file does not exist"
    exit 1
fi

# Set output filename if not provided
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${1%.*}"
fi

# Display verbose information
if [ "$VERBOSE" = true ]; then
    echo "Arguments being set:"
    echo "  GDB = $GDB"
    echo "  RUN = $RUN"
    echo "  BREAK = $BREAK"
    echo "  QEMU = $QEMU"
    echo "  Input File = $1"
    echo "  Output File = $OUTPUT_FILE"
    echo "  Verbose = $VERBOSE"
    echo "  64 bit mode = $BITS" 
    echo ""
    echo "Assembly compilation started..."
fi

# Compile assembly code
if [ "$BITS" = true ]; then
    gcc -nostdlib -m64 -o "$OUTPUT_FILE" "$1" && echo ""
else
    gcc -nostdlib -m32 -o "$OUTPUT_FILE" "$1" && echo ""
fi

# Display verbose information
if [ "$VERBOSE" = true ]; then
    echo "Assembly compilation finished"
fi

# Run executable in QEMU emulator
if [ "$QEMU" = true ]; then
    echo "Starting QEMU ..."
    echo ""

    if [ "$BITS" = true ]; then
        qemu-x86_64 "$OUTPUT_FILE" && echo ""
    else
        qemu-i386 "$OUTPUT_FILE" && echo ""
    fi

    exit 0
fi

# Run GDB command on executable
if [ "$GDB" = true ]; then
    gdb_params=()
    gdb_params+=(-ex "b ${BREAK}")

    if [ "$RUN" = true ]; then
        gdb_params+=(-ex "r")
    fi

    gdb "${gdb_params[@]}" "$OUTPUT_FILE"
fi
