#!/bin/bash

JOBID=$1

if [ -z "$JOBID" ]; then
  echo "Usage: $0 <jobid>"
  exit 1
fi

echo "Waiting for job $JOBID to finish..."

# Loop until job no longer in queue
while squeue -j $JOBID > /dev/null 2>&1 && squeue -j $JOBID | grep -q $JOBID; do
  sleep 30
  echo "Not done yet!"
done

echo "Job $JOBID finished!"

# Send desktop notification (Linux with notify-send)
if command -v notify-send &> /dev/null; then
  notify-send "Slurm Job $JOBID" "Your job has finished."
fi

# Or send an email (adjust your email below)
# echo "Your job $JOBID has finished." | mail -s "Slurm Job Finished" youremail@example.com
