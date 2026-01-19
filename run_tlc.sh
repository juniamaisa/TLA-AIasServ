#!/bin/bash
# run_tlc.sh — Shell script to execute TLC model checking for MTCP/MEP protocols

java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC \
  -workers 4 \
  -config MTCP_MEP.cfg \
  MTCP_MEP.tla
