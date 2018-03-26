#!/bin/bash

set -o errexit

source /usr/local/crf/bashlib/nagios.bashlib
nagios.deployLocal
