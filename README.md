# Baremetal install suite for The Graph decentralised stack
This work is developped and tested specifically on Ubuntu 18.04 LTS, though should in theory work on any recent Ubuntu & Debian version.
This work is blessed to be suported by a [grant from The Graph foundation](https://www.notion.so/The-Graph-Foundation-Grants-445138b51ce144689495cb5e37be0ef7) and published under Apache License 2.0

## Changelog 
Status of the codebase

### 14th of June, 2021
graph-node 0.22.0
agent & service 0.16.0

Major code refactor & updated with the latest (compared to Mission Control scripts).  Still individual installers, rather than an integrated suite.
Centralised config files, yet split into mainnet + testnet + common.  Should connect the different components by itself when used in a single server setup, but still require manual tweaking for multi-server setups.
HTTPS (optional) isn't yet part of the installation routines.

* Please run postgres installer before the others, it'll generate a password that gets appended to the variables, if none was defined.
* The graph-node script allows to specify "indexer", "query" or "both" [default] as argument at invocation.
* Most scripts need to be first run with sudo and then again under the user it created.
* Scripts will finish printing instructions for a few manual steps to take (e.g. start / enable systemd units, grafana-postgres rights script to run, etc).

Pre-configured ports in mainnet & testnet variables config files are made so both can be run in parallel and under different user.