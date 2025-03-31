#!/bin/sh

make clean
make all

echo
echo "Start node: \"Tom Hanks\";  Depth: 3 - Sequential Graph Traversal - used professor's version"
./level_client "Tom Hanks" 3

echo
echo "Start node: \"Tom Hanks\";  Depth: 3 - Parallel Graph Traversal"
./par_level_client "Tom Hanks" 3

