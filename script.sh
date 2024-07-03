#!/bin/bash

for branch in $(git branch --list | cut -c 3-); do
  git checkout $branch
done

