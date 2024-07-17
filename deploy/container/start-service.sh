#!/bin/bash

# db initialize
npm run migrate up

# teletype-server start
npm run start
