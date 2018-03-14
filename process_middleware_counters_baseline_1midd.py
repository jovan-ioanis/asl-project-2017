"""
     ASL project - fall 2017

        author: Jovan Nikolic

        Processes logs generated by middleware
"""
import numpy as np
import csv
import math

path_base = "data/baseline_1midd/middleware"
beginning_of_time_path = "plots/baseline_1midd/timers/beginning_of_time.csv"
plot_path_base = "plots/baseline_1midd/timers/"
client_threads_basename = "clientThreads_"
worker_threads_basename = "_workerThreads_"
counters_basename = "counters_"
timers_basename = "timers_"

number_of_middlewares = 1
virtual_clients_pt = [1, 5, 8, 15, 22, 28, 32, 42, 52, 64]
worker_threads = [8, 16, 32, 64]
command_types = ["_S1-G0", "_S0-G1"]
repetitions = 3
memtier_vms = 1
memtier_instances_per_vm = 1
memtier_threads_per_inst = 2
step = 1e9

beginning_of_time = {}      # <SET/GET, <cpt, <wt, <rep, value> > > >


def read_beginning_of_time():
    beginning_of_time["SET"] = {}
    beginning_of_time["GET"] = {}
    with open(beginning_of_time_path, 'r') as file:
        data = file.readlines()
        data = [x.strip() for x in data]
        for k, line in enumerate(data):
            if k == 0:
                continue
            parsed_line = line.split(',')
            [x.strip() for x in parsed_line]
            cpt = int(parsed_line[0])
            wt = int(parsed_line[1])
            if cpt not in beginning_of_time["SET"]:
                beginning_of_time["SET"][cpt] = {}
            beginning_of_time["SET"][cpt][wt] = {}
            for rep in range(repetitions):
                beginning_of_time["SET"][cpt][wt][rep] = float(parsed_line[2 + rep])
        file.close()


def print_csv(header, path, full_data):
    print("Header length is: " + str(len(header)))
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



def read_counters(command_type):
    throughputs = {}
    for cpt in virtual_clients_pt:
        print("Virtual clients: " + str(cpt))
        throughputs[cpt] = {}
        for wt in worker_threads:
            print("  Worker threads: " + str(wt))
            throughputs[cpt][wt] = []           # holds throughputs over repetitions
            for rep in range(repetitions):
                # print("    rep: " + str(rep))
                throughputs_per_thread = []
                for worker in range(wt):
                    # print("      current worker: " + str(worker))
                    path = path_base + "1" + "/" + \
                        client_threads_basename + str(cpt) + \
                        worker_threads_basename + str(wt) + \
                        command_type + \
                        "_rep" + str(rep + 1) + "/logs/" + \
                        counters_basename + str(worker) + ".log"

                    with open(path, 'r') as counter_file:
                        counter_data = counter_file.readlines()
                        counter_data = [x.strip() for x in counter_data]
                        missing_data = 0
                        if len(counter_data) == 0:
                            print("================================")
                            missing_data += 1
                            continue
                        # print("Counter data length: " + str(len(counter_data)))
                        parsed_line = counter_data[(len(counter_data)-1)].split(',')
                        [x.strip() for x in parsed_line]
                        timestamp = float(parsed_line[0])
                        num_requests = float(parsed_line[1])
                        timestamp_zero = beginning_of_time["SET"][cpt][wt][rep]
                        time_diff = (timestamp - timestamp_zero) / step         # must be in seconds
                        throughput = num_requests / time_diff
                        throughputs_per_thread.append(throughput)
                    counter_file.close()

                avg_throughput_per_thread = np.mean(np.asarray(throughputs_per_thread))
                for k in range(missing_data):
                    throughputs_per_thread.append(avg_throughput_per_thread)
                sum_throughputs = np.sum(np.asarray(throughputs_per_thread))
                throughputs[cpt][wt].append(sum_throughputs)

    final_throughputs = {}
    for cpt in virtual_clients_pt:
        final_throughputs[cpt] = {}
        for wt in worker_threads:
            mean_val = np.mean(np.asarray([throughputs[cpt][wt][0], throughputs[cpt][wt][1], throughputs[cpt][wt][2]]))
            std_val = np.std(np.asarray([throughputs[cpt][wt][0], throughputs[cpt][wt][1], throughputs[cpt][wt][2]]))
            mean_respt = (memtier_vms * memtier_instances_per_vm * memtier_threads_per_inst * cpt * 1000) / mean_val
            final_throughputs[cpt][wt] = [mean_val, std_val, mean_respt]

    header = ["#Number of Clients",
              "Mean Throughput [req/s] - 8 WORKERS", "Std Dev Throughput - 8 WORKERS", "Response Time [ms] - 8 WORKERS",
              "Mean Throughput [req/s] - 16 WORKERS", "Std Dev Throughput - 16 WORKERS", "Response Time [ms] - 16 WORKERS",
              "Mean Throughput [req/s] - 32 WORKERS", "Std Dev Throughput - 32 WORKERS", "Response Time [ms] - 32 WORKERS",
              "Mean Throughput [req/s] - 64 WORKERS", "Std Dev Throughput - 64 WORKERS", "Response Time [ms] - 64 WORKERS"]
    path = plot_path_base + "throughput.csv"
    print_csv(header, path, final_throughputs)


def main():
    read_beginning_of_time()
    read_counters(command_types[0])


if __name__ == "__main__":
    main()






