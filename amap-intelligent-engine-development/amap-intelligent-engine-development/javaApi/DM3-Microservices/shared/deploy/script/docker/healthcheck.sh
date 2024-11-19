#!/bin/sh

curl --fail --silent http://localhost:$APP_PORT/actuator/health | grep "UP" || exit 1