"""
     ASL project - fall 2017

        author: Jovan Nikolic

        Processes aggregated logs generated by middleware
"""
import numpy as np
import csv

agg_path_base = "aggregated_data/baseline_2midd/counters/"
plot_path_base = "plots/baseline_2midd/timers/"
name_base = "timer_aggregated_data_"
client_threads_basename = "clientThreads_"
worker_threads_basename = "_workerThreads_"
counters_basename = "counter_"
timers_basename = "timers_"

number_of_middlewares = 2
virtual_clients_pt = [1, 5, 8, 15, 22, 28, 32, 42, 52, 64]
worker_threads = [8, 16, 32, 64]
command_types = ["_S1-G0", "_S0-G1"]
repetitions = 3

memtier_vms = 1
memtier_instances_per_vm = 2
memtier_threads_per_inst = 1


def read_csv(cpt, wt, command_type):

    rep1 = []
    rep2 = []
    rep3 = []

    for mw in range(number_of_middlewares):
        print("READING MW: " + str(mw))
        current_mw = mw + 1
        path = agg_path_base + "throughput_" + "mw" + str(current_mw) + "_cpt" + str(cpt) + \
               "_wt" + str(wt) + \
               command_type + ".csv"

        counter = 0
        with open(path, 'r') as file:
            data = file.readlines()
            data = [x.strip() for x in data]
            for k, line in enumerate(data):
                if k == 0:
                    continue
                if k == len(data)-1:
                    continue
                parsed_line = line.split(',')
                [x.strip() for x in parsed_line]
                if mw == 0:
                    rep1.append(float(parsed_line[1]))
                    rep2.append(float(parsed_line[2]))
                    rep3.append(float(parsed_line[3]))
                else:
                    if counter >= len(rep1):
                        continue
                    rep1[counter] += float(parsed_line[1])
                    rep2[counter] += float(parsed_line[2])
                    rep3[counter] += float(parsed_line[3])
                    counter += 1
            file.close()

    cut_left = 5
    cut_right = min([len(rep1), len(rep2), len(rep3)]) - 2

    throughput_mean_1 = np.mean(np.asarray(rep1)[cut_left:cut_right])
    throughput_mean_2 = np.mean(np.asarray(rep2)[cut_left:cut_right])
    throughput_mean_3 = np.mean(np.asarray(rep3)[cut_left:cut_right])
    # print("tps are: " + str(throughput_mean_1) + " " + str(throughput_mean_2) + " " + str(throughput_mean_3))
    throughput_mean = np.mean(np.asarray([throughput_mean_1, throughput_mean_2, throughput_mean_3]))
    throughput_std = np.std(np.asarray([throughput_mean_1, throughput_mean_2, throughput_mean_3]))
    # print("final tps = " + str(throughput_mean) + ", final std = " + str(throughput_std))
    response_time = memtier_vms * memtier_instances_per_vm * memtier_threads_per_inst * cpt * 1000 / throughput_mean

    return [throughput_mean, throughput_std, response_time]


def print_csv(header, path, full_data):
    total_clients = memtier_vms * memtier_instances_per_vm * memtier_threads_per_inst * np.asarray(virtual_clients_pt)
    print("Number of rows is: " + str(len(total_clients)))

    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(total_clients)):
            one_row = {}
            i = 0
            one_row[header[i]] = total_clients[row]
            i += 1
            for wt in worker_threads:
                one_row[header[i]] = full_data[virtual_clients_pt[row]][wt][0]
                i += 1
                one_row[header[i]] = full_data[virtual_clients_pt[row]][wt][1]
                i += 1
                one_row[header[i]] = full_data[virtual_clients_pt[row]][wt][2]
                i += 1
            writer.writerow(one_row)
        csv_file.close()


def main():
    for z, command_type in enumerate(command_types):
        big_data = {}
        if z == 0:
            suffix = "write-only"
        else:
            suffix = "read-only"
        print("Command type = " + suffix)
        for cpt in virtual_clients_pt:
            print(" Virtual clients: " + str(cpt))
            data = {}
            for wt in worker_threads:
                print("   Workers: " + str(wt))
                data[wt] = read_csv(cpt, wt, command_type)
            big_data[cpt] = data
        header = ["#Number of Clients",
                  "Mean Throughput [req/s] - 8 WORKERS", "Std Dev Throughput - 8 WORKERS", "Response Time [ms] - 8 WORKERS",
                  "Mean Throughput [req/s] - 16 WORKERS", "Std Dev Throughput - 16 WORKERS", "Response Time [ms] - 16 WORKERS",
                  "Mean Throughput [req/s] - 32 WORKERS", "Std Dev Throughput - 32 WORKERS", "Response Time [ms] - 32 WORKERS",
                  "Mean Throughput [req/s] - 64 WORKERS", "Std Dev Throughput - 64 WORKERS", "Response Time [ms] - 64 WORKERS"]
        path = plot_path_base + "throughput_" + suffix + ".csv"
        print_csv(header, path, big_data)


if __name__ == "__main__":
    main()

