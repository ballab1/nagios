#!/bin/bash

set -o errexit

nagios.setHtPasswd
nagios.setPermissionsOnVolumes
nagios.removeOldFiles
nagios.redeployConfig
