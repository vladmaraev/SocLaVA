#!/bin/bash
ssh -t -t -f hacienda srun -p hard --gpus-per-node=1 -t 1 --pty ./ollama.sh
# ssh -t -t -f hacienda -L 10012:127.0.0.1:10012 ssh led -L 10012:127.0.0.1:10012
