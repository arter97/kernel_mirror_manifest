# Kernel build mirror manifest

This repository provides a cron-updated manifest for mirroring all of CodeAurora and Google's kernel-related (GKI) repositories.

## How to use

```
mkdir -p /mirror/kernelplatform
cd /mirror/kernelplatform
repo init -u https://github.com/arter97/kernel_mirror_manifest --mirror
repo sync -j16
```

#### cron.sh

For cronjob registration. This is executed every 8 AM KST.
