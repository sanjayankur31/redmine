#!/bin/bash

# Copyright 2019 Ankur Sinha
# Author: Ankur Sinha <sanjay DOT ankur AT gmail DOT com> 
# File : run-redmine.sh
#

# Runs the redmine webrick server. To be used in the container.
bundle exec rails server webrick -e production
