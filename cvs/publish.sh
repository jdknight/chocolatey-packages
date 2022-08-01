#!/usr/bin/env bash

exec choco push *.nupkg --source https://push.chocolatey.org/ $@
