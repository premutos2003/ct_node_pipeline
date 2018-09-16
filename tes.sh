#!/usr/bin/env bash






            docker build -t ${PROJECT_NAME}  --build-arg entry="${entrypoint}" \
                && --build-arg port=${APP_PORT}  --build-arg folder=app .