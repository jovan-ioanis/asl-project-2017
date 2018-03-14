"""
    ASL project - fall 2017

    author: Jovan Nikolic

    Processes json log file produced by memtiers
"""

import json
import numpy as np
import csv

plots_base_name = "plots/baseline_nomidd_1server/"
file_base_name = "data/baseline_nomidd_1server/"
json_file_base_name = file_base_name + "json_output_file_"
throughput_literal = "Ops/sec"
hits_literal = "Hits/sec"
latency_literal = "Latency"

# a = ["SET"]
# b = ["Sets"]
# c = ["_writeonly"]
# d = ["WRITE-ONLY"]
#
a = ["GET", "SET"]
b = ["Gets", "Sets"]
c = ["_readonly", "_writeonly"]
d = ["READ-ONLY", "WRITE-ONLY"]

# experimental setup
memtier_vms = 3
memtier_instances_per_vm = 1
num_threads_per_instance = 2
clients_per_thread = [1, 5, 8, 14, 19, 23, 28, 32, 42, 52, 64]
repetitions = 3

data = {}  # <GET/SET, <cpt, <rep, <vm, json_file> > > >


def make_filename(cpt, rep, readonly, vm):
    if readonly:
        c = "_S0-G1_"
    else:
        c = "_S1-G0_"
    return json_file_base_name + "cpt" + str(cpt) + "_rep" + str(rep) + c + "vm" + str(vm) + ".json"


def read_jsons(readonly):
    bigger_dict = {}
    for cpt in clients_per_thread:
        big_dict = {}
        for rep in range(1, repetitions + 1):
            small_dict = {}
            for vm in range(1, memtier_vms + 1):
                with open(make_filename(cpt, rep, readonly, vm)) as json_file:
                    json_data = json.load(json_file)
                    json_file.close()
                    small_dict[vm] = json_data
            big_dict[rep] = small_dict
        bigger_dict[cpt] = big_dict
    if readonly:
        data['GET'] = bigger_dict
    else:
        data['SET'] = bigger_dict


def print_csv(full_header, full_data, path):
    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=full_header)
        writer.writeheader()

        for row in range(len(full_data[0])):
            one_row = {}
            for column in range(len(full_header)):
                one_row[full_header[column]] = full_data[column][row]
            writer.writerow(one_row)

        csv_file.close()


def assemble_and_print():
    full_data = []
    total_num_clients = memtier_vms * memtier_instances_per_vm * num_threads_per_instance * np.asarray(
        clients_per_thread)
    full_data.append(total_num_clients)

    for j in range(len(a)):
        throughput_means = []
        throughput_stdev = []

        restime_means = []
        restime_stdev = []

        for i, cpt in enumerate(clients_per_thread):
            sums_in_reps = []
            response_times_in_reps = []
            for rep in range(1, repetitions + 1):
                sum_throughput = 0
                response_times = []
                for vm in range(1, memtier_vms + 1):
                    sum_throughput += data[a[j]][cpt][rep][vm]["ALL STATS"][b[j]][throughput_literal]
                    response_times.append(data[a[j]][cpt][rep][vm]["ALL STATS"][b[j]][latency_literal])
                sums_in_reps.append(sum_throughput)
                response_times_in_reps.append(np.mean(np.asarray(response_times)))

            average_throughput_over_repetitions = np.mean(np.asarray(sums_in_reps))
            stdev_throughput_over_repetitions = np.std(np.asarray(sums_in_reps))
            throughput_means.append(average_throughput_over_repetitions)
            throughput_stdev.append(stdev_throughput_over_repetitions)

            average_restime_over_repetitions = np.mean(np.asarray(response_times_in_reps))
            stdev_restime_over_repetitions = np.std(np.asarray(response_times_in_reps))
            restime_means.append(average_restime_over_repetitions)
            restime_stdev.append(stdev_restime_over_repetitions)

        full_data.append(throughput_means)
        full_data.append(throughput_stdev)
        full_data.append(restime_means)
        full_data.append(restime_stdev)

    # print_csv(["Number of Clients",
    #            "Average Throughput WRITE-ONLY", "Std Dev Throughput WRITE-ONLY",
    #            "Average Response Time WRITE-ONLY", "Std Dev Response Time WRITE-ONLY"], full_data,
    #           plots_base_name + "source_baseline_nomidd_1server.csv")

    print_csv(["Number of Clients", "Average Throughput READ-ONLY", "Std Dev Throughput READ-ONLY",
               "Average Response Time READ-ONLY", "Std Dev Response Time READ-ONLY",
               "Average Throughput WRITE-ONLY", "Std Dev Throughput WRITE-ONLY",
               "Average Response Time WRITE-ONLY", "Std Dev Response Time WRITE-ONLY"], full_data,
              plots_base_name + "source_baseline_nomidd_1server.csv")


def main():
    read_jsons(False)
    read_jsons(True)
    assemble_and_print()


if __name__ == "__main__":
    main()
