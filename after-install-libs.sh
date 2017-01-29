#!/usr/bin/env bash

ldconfig /usr/local/lib >/dev/null 2>&1 || echo "ldconfig not found" > /dev/null
