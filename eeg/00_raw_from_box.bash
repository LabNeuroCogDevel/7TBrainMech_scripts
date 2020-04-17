#!/usr/bin/env bash
# 20200417 - from sync to copy so no file is deleted
rclone copy "box:EEG_BrainMechR01/" /Volumes/Hera/Raw/EEG/7TBrainMech -v
