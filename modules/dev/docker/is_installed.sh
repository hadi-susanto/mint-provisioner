#!/usr/bin/env bash

command -v docker >/dev/null 2>&1 &&
    command -v containerd >/dev/null 2>&1 &&
    docker compose version >/dev/null 2>&1 &&
    docker buildx version >/dev/null 2>&1
