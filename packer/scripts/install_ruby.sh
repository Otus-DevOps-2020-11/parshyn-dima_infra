#!/usr/bin/env bash
apt list --upgradable
apt -y update
apt -y install ruby-full ruby-bundler build-essential git
