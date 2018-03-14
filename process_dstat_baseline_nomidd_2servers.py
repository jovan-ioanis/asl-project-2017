"""
     ASL project - fall 2017

        author: Jovan Nikolic

        Processes aggregated logs generated by middleware
"""

import numpy as np
import csv

base_path = "data/baseline_nomidd_2servers/dstat_"
output_base_path = "plots/baseline_nomidd_2servers/"
machine_types = ["memtier", "memcached"]
virtual_clients_pt = [1, 5, 8, 13, 20, 27, 32, 42, 52, 64, 78, 96]
commands = ["r", "w"]
columns = ["user cpu", "system cpu", "net_received", "net_sent", "system csw"]
repetitions = 3


def read_csv(machine_type, cpt, command):
    full_data = {}
    for column in columns:
        full_data[column] = []
    if machine_type == machine_types[0]:
        max_id = 1
    elif machine_type == machine_types[1]:
        max_id = 2
    else:
        max_id = 0
    for rep in range(repetitions):
        full_data_pr = {}
        for column in columns:
            full_data_pr[column] = []
        current_rep = rep + 1
        print("          rep: " + str(current_rep))
        for i in range(max_id):
            ID = i + 1
            print("        id: " + str(ID))
            path = base_path + machine_type + str(ID) + "_cpt" + str(cpt) + "_rep" + str(current_rep) + "_" + command + ".csv"
            with open(path, 'r') as file:
                data = file.readlines()
                data = [x.strip() for x in data]
                for k, line in enumerate(data):
                    if k < 7:
                        continue
                    parsed_line = line.split(',')
                    [x.strip() for x in parsed_line]

                    full_data_pr[columns[0]].append(float(parsed_line[0]))
                    full_data_pr[columns[1]].append(float(parsed_line[1]))
                    full_data_pr[columns[2]].append(float(parsed_line[18]))
                    full_data_pr[columns[3]].append(float(parsed_line[19]))
                    full_data_pr[columns[4]].append(float(parsed_line[25]))
        full_data[columns[0]].append(np.mean(np.asarray(full_data_pr[columns[0]])))
        full_data[columns[1]].append(np.mean(np.asarray(full_data_pr[columns[1]])))
        full_data[columns[2]].append(np.mean(np.asarray(full_data_pr[columns[2]])))
        full_data[columns[3]].append(np.mean(np.asarray(full_data_pr[columns[3]])))
        full_data[columns[4]].append(np.mean(np.asarray(full_data_pr[columns[4]])))
    full_data_means = {}
    full_data_std = {}
    for z, column in enumerate(columns):
        if z == 2 or z == 3:
            full_data_means[column] = np.mean(np.asarray(full_data[column]) / 1024)
            full_data_std[column] = np.std(np.asarray(full_data[column]) / 1024)
        else:
            full_data_means[column] = np.mean(np.asarray(full_data[column]))
            full_data_std[column] = np.std(np.asarray(full_data[column]))
    return full_data_means, full_data_std


def print_csv(header, path, full_data_means, full_data_stds):
    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(virtual_clients_pt)):
            one_row = {}
            i = 0
            one_row[header[i]] = 2*virtual_clients_pt[row]
            i += 1
            for k in range(len(columns)):
                one_row[header[i]] = full_data_means[commands[0]][virtual_clients_pt[row]][columns[k]]
                i += 1
                one_row[header[i]] = full_data_stds[commands[0]][virtual_clients_pt[row]][columns[k]]
                i += 1
                one_row[header[i]] = full_data_means[commands[1]][virtual_clients_pt[row]][columns[k]]
                i += 1
                one_row[header[i]] = full_data_stds[commands[1]][virtual_clients_pt[row]][columns[k]]
                i += 1
            writer.writerow(one_row)
        csv_file.close()


def process():
    for machine_type in machine_types:
        print("Machine: " + machine_type)
        full_data_means = {}
        full_data_stds = {}
        for command in commands:
            print("  Command: " + command)
            full_data_means[command] = {}
            full_data_stds[command] = {}
            for cpt in virtual_clients_pt:
                print("    Clients: " + str(cpt))
                means, stds = read_csv(machine_type, cpt, command)
                full_data_means[command][cpt] = means
                full_data_stds[command][cpt] = stds
        header = ["#Clients",
                  "Mean User CPU - READ-ONLY", "Std User CPU - READ-ONLY",
                  "Mean User CPU - WRITE-ONLY", "Std User CPU - WRITE-ONLY",
                  "Mean System CPU - READ-ONLY", "Std System CPU - READ-ONLY",
                  "Mean System CPU - WRITE-ONLY", "Std System CPU - WRITE-ONLY",
                  "Mean Net-Received - READ-ONLY", "Std Net-Received - READ-ONLY",
                  "Mean Net-Received - WRITE-ONLY", "Std Net-Received - WRITE-ONLY",
                  "Mean Net-Sent - READ-ONLY", "Std Net-Sent - READ-ONLY",
                  "Mean Net-Sent - WRITE-ONLY", "Std Net-Sent - WRITE-ONLY",
                  "Mean Context Switches - READ-ONLY", "Std Context Switches - READ-ONLY",
                  "Mean Context Switches - WRITE-ONLY", "Std Context Switches - WRITE-ONLY"]
        path = output_base_path + "dstat_" + machine_type + ".csv"
        print_csv(header, path, full_data_means, full_data_stds)


def main():
    process()


if __name__ == "__main__":
    main()