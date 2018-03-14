"""
    ASL project - fall 2017

    author: Jovan Nikolic

    Processes json log file produced by memtiers
"""

import json
import numpy as np
import csv

plots_base_name = "plots/experiment_write-only/"
file_base_name = "data/experiment_write-only/"
csv_file_name = "source_experiment_write-only.csv"
json_file_base_name = file_base_name + "json_output_file_"
throughput_literal = "Ops/sec"
hits_literal = "Hits/sec"
latency_literal = "Latency"

a = ["SET"]
b = ["Sets"]
c = ["_writeonly"]
d = ["WRITE-ONLY"]
e = ["_S1-G0_"]

# experimental setup
memtier_vms = 3
memtier_instances_per_vm = 2
num_threads_per_instance = 1
virtual_clients_pt = [1, 5, 8, 15, 22, 28, 32, 42, 52, 64]
worker_threads = [8, 16, 32, 64]
repetitions = 3

dict = {}


def make_filename(instance, cpt, wt, rep, index, vm):
    c = e[index]
    return json_file_base_name + "inst" + str(instance) + "_cpt" + str(cpt) + "_wt" + str(wt) + "_rep" + str(rep) + c + "vm" + str(vm) + ".json"


def read_jsons(index):
    command = a[index]

    dict[command] = {}
    for cpt in virtual_clients_pt:
        dict[command][cpt] = {}
        for wt in worker_threads:
            dict[command][cpt][wt] = {}
            for rep in range(1, repetitions + 1):
                dict[command][cpt][wt][rep] = {}
                for vm in range(1, memtier_vms + 1):
                    dict[command][cpt][wt][rep][vm] = {}
                    for inst in range(1, memtier_instances_per_vm + 1):
                        with open(make_filename(inst, cpt, wt, rep, index, vm)) as json_file:
                            json_data = json.load(json_file)
                            json_file.close()
                            dict[command][cpt][wt][rep][vm][inst] = json_data
                            json_file.close()


def assemble_and_print():
    total_num_clients = memtier_vms * memtier_instances_per_vm * num_threads_per_instance * np.asarray(
        virtual_clients_pt)

    full_data = {}

    for j in range(len(a)):
        full_data[a[j]] = {}
        for cpt in virtual_clients_pt:
            full_data[a[j]][cpt] = {}
            for wt in worker_threads:
                throughputs = []
                restimes = []

                for rep in range(1, repetitions + 1):
                    tpt = []
                    rst = []
                    for vm in range(1, memtier_vms + 1):
                        for inst in range(1, memtier_instances_per_vm + 1):
                            tpt.append(dict[a[j]][cpt][wt][rep][vm][inst]["ALL STATS"][b[j]][throughput_literal])
                            rst.append(dict[a[j]][cpt][wt][rep][vm][inst]["ALL STATS"][b[j]][latency_literal])
                    sum_tpt = np.sum(np.asarray(tpt))
                    avg_rst = np.mean(np.asarray(rst))
                    throughputs.append(sum_tpt)
                    restimes.append(avg_rst)
                throughput_means = np.mean(np.asarray(throughputs))
                throughput_stdev = np.std(np.asarray(throughputs))
                restime_means = np.mean(np.asarray(restimes))
                restime_stdev = np.mean(np.asarray(restimes))

                full_data[a[j]][cpt][wt] = [throughput_means, throughput_stdev, restime_means, restime_stdev]

    for j in range(len(d)):
        path = plots_base_name + "memtier_logs_experiment_write-only_" + d[j] + ".csv"
        header = ["Number of Clients",
                  "Mean Throughput [req/s] " + d[j] + " - 8 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 8 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 8 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 8 WORKERS",
                  "Mean Throughput [req/s] " + d[j] + " - 16 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 16 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 16 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 16 WORKERS",
                  "Mean Throughput [req/s] " + d[j] + " - 32 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 32 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 32 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 32 WORKERS",
                  "Mean Throughput [req/s] " + d[j] + " - 64 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 64 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 64 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 64 WORKERS"]
        print_csv(header, path, total_num_clients, full_data, a[j])


def print_csv(header, path, total_num_clients, full_data, command):
    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(total_num_clients)):
            one_row = {}
            i = 0
            one_row[header[i]] = total_num_clients[row]
            i += 1
            for wt in worker_threads:
                for k in range(4):
                    one_row[header[i]] = full_data[command][virtual_clients_pt[row]][wt][k]
                    i += 1
            writer.writerow(one_row)
        csv_file.close()


def main():
    for i in range(len(a)):
        read_jsons(i)
    assemble_and_print()


if __name__ == "__main__":
    main()