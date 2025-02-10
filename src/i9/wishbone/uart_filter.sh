#!/bin/bash
exec $(dirname $0)/gtkwave-sigrok-filter.py -P uart
