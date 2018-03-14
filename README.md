# Advanced Systems Lab - Fall 2017

author: **Jovan Nikolic**
**ETH**, Zurich, Switzerland

This repository contains code for project of Advanced System Lab course of ETH, Zurich.

**Final report** is available [here](https://github.com/jovan-ioanis/asl-project-2017/blob/master/report.pdf).
**Project description** is available [here](https://github.com/jovan-ioanis/asl-project-2017/blob/master/project-description.pdf).

## Organization of data, scripts and plots

Size of raw data obtained from experiments is around 160GB, hence it is not uploaded to the repository. However, aggregated data from middleware logs over 1 second window, is uploaded and can be found in `aggregated_data` folder. Data from `dstat` tool, `ping` results and logs from memtier client are not uploaded as well. All data is available on request.

### Organization of data

In `aggregated_data` folder, data is organized per experiments in the following way:
- `baseline_1midd` contains data from baseline experiment with **1 middleware**
- `baseline_2midd` contain data from baseline experiment with **2 middlewares**
- `baseline_2midd_2vms` contains data from repetition of experiment with **2 middlewares under write-only load with 2 client machines**
- `experiment_write-only` contains data from **write-only** experiments from Section 4
- `experiment_gets` contain data from **gets and multi-gets** experiments from Section 5
- `experiment_2k` contains data from experiments conducted for **2k analysis**
- `queueing theory` contains data extracted from previous experiments for input values in **queueing models**
- `baseline_nomidd_1server` contains raw data from baseline **without middleware with 1 server** experiment
- `baseline_nomidd_2servers` contains raw data from baseline **without middleware with 2 servers** experiment

In `baseline_nomidd_1server` the following naming convention applies:

- `json_output_file_cpt_`**X**`_rep`**Y**`_`**ZZZZ**`_vm`**N**`.json` represents output file of memtier instance, where **X** is number of virtual clients per thread at memtier, **Y** is repetition number = {1, 2, 3}, **ZZZZ** is `S0-G1` for read-only load and `S1-G0` for write-only load, **N** is virtual machine id = {1, 2, 3}.

- `dstat_`__*machine*__N`_cpt`**X**`_rep`**Y**`_`**S**`.csv` represents output file of `dstat` tool, where __*machine*__ = {"memtier", "memcached"}, **N** is id of machine instance, **X** is number of virtual clients per thread at memtier, **Y** is repetition number = {1, 2, 3} and **S** is "r" for read-only and "w" for write-only. Ping results are identified in similar way.

In `baseline_nomidd_2servers` the following naming convention applies:

- for `dstat` logs and ping results, convention is the same as above

- `json_output_file_inst`**A**`_cpt`**X**`_rep`**Y**`_`**ZZZZ**`_vm`**N**`.json` represents output file of memtier clients, where **A** is instance id = {1, 2}, **X** is number of virtual clients per thread at memtier, **Y** is repetition number = {1, 2, 3}, **ZZZZ** is `S0-G1` for read-only load and `S1-G0` for write-only load, **N** is virtual machine id = {1, 2, 3}.

In `queueing_theory` folder, files `noq_1midd.txt` and `noq_2midd.txt` contain service times that are input for network of queues models with 1 and 2 middlewares, and `mm_values.ods` is Libre Office (~ MC Excel) table with sign tables for M/M/1 and M/M/m models.

In all other folders, data is divided in `timers` and `counters` folders. Folder `timers` contains aggregated time-related data like response time, server-service time, net-thread processing time and so on. The naming convention is quite clear: `timer_aggregated_data_clientThreads_`**X**`_workerThreads_`**M**`_`**ZZZZ**`.csv` where **X** is number of virtual clients per thread at memtier, **M** is number of workers per middleware and **ZZZZ** is `S0-G1` for read-only load and `S1-G0` for write-only load. Folder `counters` contains throughput aggregates and files are named similarly: `throughput_`**X**`_workerThreads_`**M**`_`**ZZZZ**`.csv`, where **X** is number of virtual clients per thread at memtier, **M** is number of workers per middleware and **ZZZZ** is `S0-G1` for read-only load and `S1-G0` for write-only load. In cases with multiple middleware instances, ID of middleware is added to the filename with tag `mw`. In `experiment_gets` folder, filename includes (human-readable) information about number of keys and if sharding is enabled.

### Organization of plots

Plots are organized in separate folders based on experiments, and folders are named the same way as in `aggregated_data` folder. Inside each of these folders, there is folder called `timers` which includes all final tables and plots from which middleware-related-figures in the report are plotted (including throughput!). Outside of that folder, final tables and plots regarding memtier are located. Filenames are human-readable.

All plots are generated using `gnuplot`, and all scripts are next to the files they use for plotting.

Global figures and diagrams like flow chart, architecture of the system and illustartions of network of queues models are located directly in `plots` folder.

### Organization of scripts

Bash shell scripts used for running experiments on Azure are located next to `src` folder: `baseline_1midd.sh`, `baseline_2mid.sh`, `baseline_2midd_repeating.sh`, `baseline_nomidd_1server.sh`, `baseline_nomidd_2servers.sh`, `experiments_2k.sh`, `experiment_gets.sh`, `experiment_write-only.sh`. The scripts do not require any input parameters, all parameters are specified inside. For rerun, path to `known_hosts` file must be updated, and scripts assume that virtual machines are already running.

`Python` scripts for analyzing logs from middleware are located next to `src` folder as well. They require raw data which is currently not uploaded to repository. Naming convention is simple: scripts starting with `process_middleware_timers` extracts and aggregates time-related data from middlewares, like response time, server-service time and so on, scripts starting with `process_middleware_counters` extracts throughput from middleware logs, scripts starting with `process_memtier_data` extracts data from memtier logs.

Scripts starting with `process_aggregated_data` use data from `aggregated_data` folder to create final tables for plotting, and to aggregate data between repetitions.

### Report folder

Report folder contains *.tex file of the report.

### Middleware code

Middleware code is located in `src/ch/ethz` folder and inside: `asltest` folder contains all main classes that build middleware, in `instrumentation` are utilities used for logging and in `utils` folder are located various utility classes. 


## Experiments Journal:	


All experiments have these parameters in common:
- `CT` is **number of threads** (set by `--thread` or `-t`), `VC` is **number of virtual clients per thread** (set by `--client` or `-c`), `CPM` = `CT` * `VC` is **number of virtual clients per memtier instance**, and final **number of clients** is `NumClients` = `NumInstances` * `CPM` = `NumInstances` * `CT` * `VC`
- choose at least **6 points** in range [1, 32] for `VC` value
- `--data-size=1024`
- `--key-maximum=10000`
- `--expiry-range=9999-10000`
- `--random-data`
- repeated at least **3 times** for statistical significance
- should have _stable phase_ of at least **60 secs**

	| **_name_** | **_type_** | **_for what_** |
	| ---------- | :---------: | :-----------: |
	| foraslvms**1** | A2	2vcpus, 3.5 GB | memtier |
	| foraslvms**2** | A2	2vcpus, 3.5 GB | memtier |
	| foraslvms**3** | A2	2vcpus, 3.5 GB | memtier |
	| foraslvms**4** | A4	8vcpus, 14 GB | middleware |
	| foraslvms**5** | A4	8vcpus, 14 GB | middleware |
	| foraslvms**6** | A1	1vcpus, 1.75 GB | memcached |
	| foraslvms**7** | A1	1vcpus, 1.75 GB | memcached |
	| foraslvms**8** | A1	1vcpus, 1.75 GB | memcached |

### Experiments outline:

- [x] **1.1. Baseline without Middleware, 1 server** can be found in `data\baseline_nomidd_1server`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 3 |
	| _memtier_ instances per VM | 1 |
	| _memtier_ threads per instance | 2 |
	| _memtier_ virtual clients per thread | (1 5 9 14 19 23 28 32) |
	| _memtier_ actual virtual clients per thread | (1 5 9 14 19 23 28 32 37 47 52) |
	| _memcached_ VMs | 1 |
	| _memcached_ instances per VM | 1 |
	| _load_ | read-only and write-only |

- [x] **1.2. Baseline withour Middleware, 2 servers** can be found in `data\baseline_nomidd_2servers`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 1 |
	| _memtier_ instances per VM | 2 |
	| _memtier_ threads per instance | 1 |
	| _memtier_ virtual clients per thread | (1 5 9 14 19 23 28 32) |
	| _memtier_ actual virtual clients per thread | (1 5 9 14 19 23 28 32 37 47 52) |
	| _memcached_ VMs | 2 |
	| _memcached_ instances per VM | 1 |
	| _load_ | read-only and write-only |

- [x] **2.1. Baseline with 1 Middleware** can be found in `data\baseline_1midd`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 1 |
	| _memtier_ instances per VM | 1 |
	| _memtier_ threads per instance | 2 |
	| _memtier_ virtual clients per thread | (1 5 9 14 19 23 28 32) |
	| _memtier_ actual virtual clients per thread | (1 5 8 14 19 23 28 32 42 52 64) |
	| _middleware_ VMs | 1 |
	| _middleware_ instances per VM | 1 |
	| _middleware_ threads per instance | (8, 16, 32, 64) |
	| _memcached_ VMs | 1 |
	| _memcached_ instances per VM | 1 |
	| _load_ | read-only and write-only |

- [x] **2.2. Baseline with 2 Middlewares** can be found in `data\baseline_2midd`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 1 |
	| _memtier_ instances per VM | 2 |
	| _memtier_ threads per instance | 1 |
	| _memtier_ virtual clients per thread | (1 5 9 14 19 23 28 32) |
	| _memtier_ actual virtual clients per thread | (1 5 8 14 19 23 28 32 42 52 64) |
	| _middleware_ VMs | 2 |
	| _middleware_ instances per VM | 1 |
	| _middleware_ threads per instance | (8, 16, 32, 64) |
	| _memcached_ VMs | 1 |
	| _memcached_ instances per VM | 1 |
	| _load_ | read-only and write-only |

- [x] **3. Throughput for Writes** can be found in `data\experiment_write-only`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 3 |
	| _memtier_ instances per VM | 2 |
	| _memtier_ threads per instance | 1 |
	| _memtier_ virtual clients per thread | (1 5 9 14 19 23 28 32) |
	| _memtier_ actual virtual clients per thread | (1 5 8 14 19 23 28 32 42 52 64) |
	| _middleware_ VMs | 2 |
	| _middleware_ instances per VM | 1 |
	| _middleware_ threads per instance | (8, 16, 32, 64) |
	| _memcached_ VMs | 3 |
	| _memcached_ instances per VM | 1 |
	| _load_ | write-only |

- [x] **4.1. GETs and multi-GETs, Sharded Case** can be found in `data\experiment_gets`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 3 |
	| _memtier_ instances per VM | 2 |
	| _memtier_ threads per instance | 1 |
	| _memtier_ virtual clients per thread | 2 |
	| _middleware_ VMs | 2 |
	| _middleware_ instances per VM | 1 |
	| _middleware_ threads per instance | 64 |
	| _memcached_ VMs | 3 |
	| _memcached_ instances per VM | 1 |
	| _load_ | read-only with (1 3 6 9) keys, sharded **_enabled_** |

- [x] **4.2. GETs and multi-GETs, Non-Sharded Case** can be found in `data\experiment_gets`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 3 |
	| _memtier_ instances per VM | 2 |
	| _memtier_ threads per instance | 1 |
	| _memtier_ virtual clients per thread | 2 |
	| _middleware_ VMs | 2 |
	| _middleware_ instances per VM | 1 |
	| _middleware_ threads per instance | 64 (or any lower number of threads that gives max throughput) |
	| _memcached_ VMs | 3 |
	| _memcached_ instances per VM | 1 |
	| _load_ | read-only with (1 3 6 9) keys, sharded **_disabled_** |

- [x] **5. 2k Analysis** can be found in `data\2k_analysis`

	| **_name_** | **_value_** |
	| ---------- | :---------: |
	| _memtier_ VMs | 3 |
	| _memtier_ instances per VM | 2 |
	| _memtier_ threads per instance | 1 |
	| _memtier_ virtual clients per thread | 32 |
	| _middleware_ VMs | (1 2) |
	| _middleware_ instances per VM | 1 |
	| _middleware_ threads per instance | (8 32) |
	| _memcached_ VMs | (2 3) |
	| _memcached_ instances per VM | 1 |
	| _load_ | write-only, read-only and 50-50-read-write, all single-keyed GET requests |


Color Palette:
1. `#D43849`
2. `#63CB9D`
3. `#0B547E`
4. `#AF71FC`
5. `#C4B205`

Tried these as well: `#63cb9d`, `#1a4b4d`, `#99c042`, `#2f1b51`, `#8f3040`, `#000000`, `#2a7d58`, `#5b1e35`, `#F24738`, `#FF9600`
