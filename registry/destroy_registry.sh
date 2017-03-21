#!/bin/sh
REGISTRY_NAME=registry
docker stop "$REGISTRY_NAME"
docker rm -v "$REGISTRY_NAME"
