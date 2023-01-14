#!/bin/bash

set -eo pipefail

if [ ! -d qcom ]; then
  echo "qcom manifest doesn't exist, cloning..."
  git clone https://git.codelinaro.org/clo/la/kernelplatform/manifest -b release qcom
fi &

if [ ! -d google ]; then
  echo "google manifest doesn't exist, cloning..."
  git clone https://android.googlesource.com/kernel/manifest google
fi &

wait

# Switch to codelinaro.org if not done already
sed -i -e 's@source.codeaurora.org/quic@git.codelinaro.org/clo@g' */.git/config

for i in qcom google; do
  cd $i
  (
    echo "Pulling updates from $i"
    git fetch --all
    git reset --hard origin/release 2>&1 || true
    echo "Updated $i"
  ) &
  cd ..
done

wait
