#!/bin/bash -ue

ARG="--config ./tools/swiftlint.yml --quiet"
# swiftlint autocorrect $ARG
swiftlint lint        $ARG

