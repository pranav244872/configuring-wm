#!/bin/bash
# Get current wallpaper path from awww
awww query 2>/dev/null | grep 'image:' | awk '{print $NF}'
