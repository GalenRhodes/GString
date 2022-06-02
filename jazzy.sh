#!/usr/bin/env bash

jazzy
rsync -avz docs/ grhodes@goober:/var/www/html/GString/
