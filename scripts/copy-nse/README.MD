# Description
- Script to copy all Notification Extension Service resource from Element X to Twake

# Steps
- Download Element X repository as zip and unzip
- Copy source code from NSE
- Apply patch: It is fix nullable slidingProxy when try decode from Keychain
- Copy DesignKit: It is local dependencies required by NSE
- Clean up: Delete zip file and unzip folder

# Setup
```
cd scripts/copy-nse
npm install
node index.js
```