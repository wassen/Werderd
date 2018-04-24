#!/bin/bash -ue

ARG="--config ./tools/swiftlint.yml"
swiftlint autocorrect $ARG
swiftlint lint        $ARG

