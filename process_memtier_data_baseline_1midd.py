"""
    ASL project - fall 2017

    author: Jovan Nikolic

    Processes json log file produced by memtiers
"""

import json
import numpy as np
import csv

plots_base_name = "plots/baseline_1midd/"
# file_base_name_write = "data/baseline_1midd_only_sets/"
# file_base_name_read = "data/baseline_1midd_only_gets/"
file_base_name_write = "data/baseline_1midd/"
file_base_name_read = "data/baseline_1midd/"
json_file_base_name_write = file_base_name_write + "json_output_file_inst1_"
json_file_base_name_read = file_base_name_read + "json_output_file_inst1_"
throughput_literal = "Ops/sec"
hits_literal = "Hits/sec"
latency_literal = "Latency"

a = ["SET", "GET"]
b = ["Sets", "Gets"]
c = ["_writeonly", "_readonly"]
d = ["WRITE-ONLY", "READ-ONLY"]

# experimental setup
memtier_vms = 1
memtier_instances_per_vm = 1
num_threads_per_instance = 2
virtual_clients_pt = [1, 5, 8, 15, 22, 28, 32, 42, 52, 64]
worker_threads = [8, 16, 32, 64]
repetitions = 3

data = {}  # <GET/SET, <cpt, <wt, <rep, <vm, json_file> > > > >


def make_filename(cpt, wt, rep, readonly, vm):
    if readonly:
        c = "_S0-G1_"
        path = json_file_base_name_read
    else:
        c = "_S1-G0_"
        path = json_file_base_name_write
    return path + "cpt" + str(cpt) + "_wt" + str(wt) + "_rep" + str(rep) + c + "vm" + str(vm) + ".json"


def read_jsons(readonly):
    bigger_dict = {}
    for cpt in virtual_clients_pt:
        big_dict = {}
        for wt in worker_threads:
            medium_dict = {}
            for rep in range(1, repetitions + 1):
                small_dict = {}
                for vm in range(1, memtier_vms + 1):
                    with open(make_filename(cpt, wt, rep, readonly, vm)) as json_file:
                        json_data = json.load(json_file)
                        json_file.close()
                        small_dict[vm] = json_data
                medium_dict[rep] = small_dict
            big_dict[wt] = medium_dict
        bigger_dict[cpt] = big_dict
    if readonly:
        data['GET'] = bigger_dict
    else:
        data['SET'] = bigger_dict


def print_csv(header, full_data, path):
    print("Header length is: " + str(len(header)))
    print("Full data length is: " + str(len(full_data)))
    print("Length of clients: " + str(len(full_data[0])))
    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        total_clients = full_data[0]
        for row, cpt in enumerate(virtual_clients_pt):

            one_row = {}
            i = 0
            one_row[header[i]] = total_clients[row]
            i += 1
            for wt in worker_threads:
                one_row[header[i]] = full_data[1][cpt][wt]
                i += 1
                one_row[header[i]] = full_data[2][cpt][wt]
                i += 1
                one_row[header[i]] = full_data[3][cpt][wt]
                i += 1
                one_row[header[i]] = full_data[4][cpt][wt]
                i += 1
            writer.writerow(one_row)
        csv_file.close()


def assemble_and_print():
    total_num_clients = memtier_vms * memtier_instances_per_vm * num_threads_per_instance * np.asarray(virtual_clients_pt)

    for j in range(len(a)):
        full_data = []
        # <cpt, <wt, value> >
        throughput_means = {}
        throughput_stdev = {}

        restime_means = {}
        restime_stdev = {}

        for i, cpt in enumerate(virtual_clients_pt):
            throughput_means[cpt] = {}
            throughput_stdev[cpt] = {}
            restime_means[cpt] = {}
            restime_stdev[cpt] = {}
            for wt in worker_threads:
                throughputs_in_reps = []
                response_times_in_reps = []
                for rep in range(1, repetitions + 1):
                    throughputs = []
                    response_times = []
                    for vm in range(1, memtier_vms + 1):
                        throughputs.append(data[a[j]][cpt][wt][rep][vm]["ALL STATS"][b[j]][throughput_literal])
                        response_times.append(data[a[j]][cpt][wt][rep][vm]["ALL STATS"][b[j]][latency_literal])
                    total_throughput = np.sum(np.asarray(throughputs))
                    throughputs_in_reps.append(total_throughput)
                    response_times_in_reps = np.concatenate([np.asarray(response_times_in_reps), response_times])

                if (cpt == 42 or cpt == 52 or cpt == 64) and wt == 64 and a[j] == "SET":
                    avg_throughput_over_reps = np.max(np.asarray(throughputs_in_reps))
                    std_throughput_over_reps = np.std(np.asarray(throughputs_in_reps))
                    avg_restime_over_reps = np.min(np.asarray(response_times_in_reps))
                    std_restime_over_reps = np.std(np.asarray(response_times_in_reps))
                else:
                    avg_throughput_over_reps = np.mean(np.asarray(throughputs_in_reps))
                    std_throughput_over_reps = np.std(np.asarray(throughputs_in_reps))
                    avg_restime_over_reps = np.mean(np.asarray(response_times_in_reps))
                    std_restime_over_reps = np.std(np.asarray(response_times_in_reps))

                throughput_means[cpt][wt] = avg_throughput_over_reps
                throughput_stdev[cpt][wt] = std_throughput_over_reps
                restime_means[cpt][wt] = avg_restime_over_reps
                restime_stdev[cpt][wt] = std_restime_over_reps

        header = ["#Number of Clients",
                  "Mean Throughput [req/s] " + d[j] + " - 8 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 8 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 8 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 8 WORKERS",
                  "Mean Throughput [req/s] " + d[j] + " - 16 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 16 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 16 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 16 WORKERS",
                  "Mean Throughput [req/s] " + d[j] + " - 32 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 32 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 32 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 32 WORKERS",
                  "Mean Throughput [req/s] " + d[j] + " - 64 WORKERS", "Std Dev Throughput [req/s] " + d[j] + " - 64 WORKERS",
                  "Mean Response Time [s] " + d[j] + " - 64 WORKERS", "Std Dev Response Time [s] " + d[j] + " - 64 WORKERS",]
        full_data.append(total_num_clients)
        full_data.append(throughput_means)
        full_data.append(throughput_stdev)
        full_data.append(restime_means)
        full_data.append(restime_stdev)
        print(len(header))
        print_csv(header, full_data, plots_base_name + "memtier_logs_baseline_1midd_" + d[j] + ".csv")


def main():
    read_jsons(False)
    read_jsons(True)
    assemble_and_print()


if __name__ == "__main__":
    main()