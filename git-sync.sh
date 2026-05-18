#!/bin/bash
cd /storage/emulated/0/Download/BAL || exit
git add .
git commit -m "auto update on $(date '+%Y-%m-%d %H:%M:%S')"
git pull origin main --allow-unrelated-histories --no-rebase
git push origin main