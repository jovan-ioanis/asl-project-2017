"""
    ASL project - fall 2017

    author: Jovan Nikolic

    Processes json log file produced by memtiers
"""

import json
import numpy as np
import csv
from pathlib import Path

big_output_path_base_name = "aggregated_data/experiment_2k/"
file_base_name = "data/experiment_2k/"
json_file_base_name = "json_output_file_"
throughput_literal = "Ops/sec"
hits_literal = "Hits/sec"
latency_literal = "Latency"

# experimental setup
memtier_vms = 3
memtier_instances_per_vm = 2
num_threads_per_instance = 1
virtual_clients_pt = 32
repetitions = 3

loads = ["S0-G1", "S1-G0", "S1-G1"]
tags = ["Gets", "Sets", "Totals"]
A = ["2", "3"]
B = ["1", "2"]
C = ["8", "32"]
metrics = ["xput", "resptime"]

all_data = {}


def read_jsons():
    for k, load in enumerate(loads):
        all_data[load] = {}
        for a in A:
            all_data[load][a] = {}
            for b in B:
                all_data[load][a][b] = {}
                for c in C:
                    all_data[load][a][b][c] = {}
                    for rep in range(repetitions):
                        all_data[load][a][b][c][rep] = {}
                        current_rep = rep + 1

                        xput = []
                        resptime = []

                        for vm in range(1, memtier_vms + 1):
                            for inst in range(1, memtier_instances_per_vm + 1):

                                path = file_base_name + json_file_base_name + "inst" + str(inst) \
                                       + "_cpt" + str(virtual_clients_pt) + "_wt" + c + "_rep" + str(current_rep) \
                                       + "_" + load + "_vm" + str(vm) + "_server" + a + "_mw" + b + ".json"

                                my_file = Path(path)
                                if not my_file.exists():
                                    print(path)
                                    continue

                                with open(path) as json_file:
                                    json_data = json.load(json_file)
                                    xput.append(json_data["ALL STATS"][tags[k]][throughput_literal])
                                    resptime.append(json_data["ALL STATS"][tags[k]][latency_literal])
                                    json_file.close()

                        all_data[load][a][b][c][rep][metrics[0]] = np.sum(np.asarray(xput))
                        all_data[load][a][b][c][rep][metrics[1]] = np.mean(np.asarray(resptime))


def print_1st_step():
    for k, load in enumerate(loads):

            path = big_output_path_base_name + "output_" + load + ".csv"
            header = ["A:servers", "B:middlewares", "C:workers",
                      "Throughput - rep1", "Throughput - rep2", "Throughput - rep3",
                      "Response time - rep1", "Response time - rep2", "Response time - rep3"]

            with open(path, 'w') as csv_file:
                writer = csv.DictWriter(csv_file, fieldnames=header)
                writer.writeheader()

                row = 0
                while row <= len(A)*len(B)*len(C):
                    one_row = {}
                    for a in A:
                        for b in B:
                            for c in C:
                                one_row[header[0]] = a
                                one_row[header[1]] = b
                                one_row[header[2]] = c
                                one_row[header[3]] = all_data[load][a][b][c][0][metrics[0]]
                                one_row[header[4]] = all_data[load][a][b][c][1][metrics[0]]
                                one_row[header[5]] = all_data[load][a][b][c][2][metrics[0]]
                                one_row[header[6]] = all_data[load][a][b][c][0][metrics[1]]
                                one_row[header[7]] = all_data[load][a][b][c][1][metrics[1]]
                                one_row[header[8]] = all_data[load][a][b][c][2][metrics[1]]
                                writer.writerow(one_row)
                                row += 1
                csv_file.close()


def main():
    read_jsons()
    print_1st_step()


if __name__ == "__main__":
    main()
