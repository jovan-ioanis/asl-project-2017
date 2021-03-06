"""
     ASL project - fall 2017

        author: Jovan Nikolic

        Processes logs generated by middleware
"""
import numpy as np
import csv
import math


class CounterStruct:
    def __init__(self):
        self.worker_id = -1
        self.command = "none"
        self.number_of_keys = -1
        self.timestamp = -1
        self.reqs = -1

path_base = "data/baseline_2midd_2vms/middleware"
beginning_of_time_path = "plots/baseline_2midd_2vms/timers/beginning_of_time_"
agg_path_base = "aggregated_data/baseline_2midd_2vms/counters/"
client_threads_basename = "clientThreads_"
worker_threads_basename = "_workerThreads_"
counters_basename = "counters_"
timers_basename = "timers_"

number_of_middlewares = 2
virtual_clients_pt = [1, 5, 8, 15, 22, 28, 32, 42, 52, 64]
worker_threads = [8, 16, 32, 64]
command_types = ["_S1-G0"]
suffixes = ["write-only"]
repetitions = 3

step = 1e9

beginning_of_time = {}  # <SET/GET, <cpt, <wt, <rep, <mw, value> > > > >


def read_beginning_of_time():
    for k, command_type in enumerate(command_types):
        beginning_of_time[command_type] = {}
        path = beginning_of_time_path + suffixes[k] + ".csv"
        print("Reading from: " + path)

        with open(path, 'r') as file:
            data = file.readlines()
            data = [x.strip() for x in data]
            for z, line in enumerate(data):
                if z == 0:
                    continue
                parsed_line = line.split(',')
                [x.strip() for x in parsed_line]
                cpt = int(parsed_line[0])
                wt = int(parsed_line[1])
                index = 2
                if cpt not in beginning_of_time[command_type]:
                    beginning_of_time[command_type][cpt] = {}
                beginning_of_time[command_type][cpt][wt] = {}
                for rep in range(repetitions):
                    beginning_of_time[command_type][cpt][wt][rep] = {}
                    beginning_of_time[command_type][cpt][wt][rep][0] = float(parsed_line[index])
                    index += 1
                for rep in range(repetitions):
                    beginning_of_time[command_type][cpt][wt][rep][1] = float(parsed_line[index])
                    index += 1
            file.close()


def read_csv(mw, command_type, cpt, wt, rep):
    """
        Returns aggregated throughput over all worker threads, per second, for one configuration
    """
    reqs_per_second = {}    # <counter, [num of reqs processed by each thread] >
                            # later it is <counter, sum of all reqs processed so far by all threads>

    if command_type == command_types[0]:
        position = 1
    else:
        position = 2
    current_mw = mw + 1

    missing_data = 0
    max_counter = 0
    for worker in range(wt):

        path = path_base + str(current_mw) + "/" + \
               client_threads_basename + str(cpt) + \
               worker_threads_basename + str(wt) + \
               command_type + \
               "_rep" + str(rep + 1) + "/logs/" + \
               counters_basename + str(worker) + ".log"

        all_records = []

        with open(path, 'r') as counter_file:
            counter_data = counter_file.readlines()
            counter_data = [x.strip() for x in counter_data]
            # print("Counter data length is: " + str(len(counter_data)))

            if len(counter_data) == 0:
                print("Missing data for: cpt = " + str(cpt) + ", wt = " + str(wt) + ", rep = " + str(rep) + ", worker = " + str(worker))
                missing_data += 1
                continue

            for k, line in enumerate(counter_data):
                if k == 0:
                    continue
                parsed_line = line.split(',')
                [x.strip() for x in parsed_line]
                cs = CounterStruct()
                cs.command = command_type
                cs.timestamp = int(parsed_line[0])
                cs.worker_id = worker
                cs.reqs = int(parsed_line[position])
                if cs.reqs == 0:
                    continue
                all_records.append(cs)
            counter_file.close()

        sorted_records = sorted(all_records, key=lambda x: x.timestamp, reverse=False)
        timestamp_zero = beginning_of_time[command_type][cpt][wt][rep][mw]

        start_time = timestamp_zero
        finish_time = start_time + step
        # print("Start time: " + str(start_time) + ", finish time: " + str(finish_time))

        counter = 0

        current_num_reqs = 0

        for i, rec in enumerate(sorted_records):
            if start_time <= rec.timestamp < finish_time and i < len(sorted_records) - 1:
                current_num_reqs = rec.reqs
            else:
                if counter not in reqs_per_second:
                    reqs_per_second[counter] = []
                reqs_per_second[counter].append(current_num_reqs)
                counter += 1
                current_num_reqs = rec.reqs

                start_time = finish_time
                finish_time = start_time + step

        max_counter = max(counter, max_counter)

    if missing_data != 0:
        for cnt in range(counter):
            avg_value = np.mean(np.asarray(reqs_per_second[cnt]))
            for i in range(missing_data):
                reqs_per_second[cnt].append(avg_value)

    print("Counter = " + str(max_counter))
    for cnt in range(max_counter):
        reqs_per_second[cnt] = np.sum(np.asarray(reqs_per_second[cnt]))
        reqs_per_second[cnt] = reqs_per_second[cnt] / (cnt + 1)

    return reqs_per_second


def print_csv(header, path, time_span, full_data):

    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(time_span)):
            one_row = {}
            for i in range(len(header)):
                if i == 0:
                    one_row[header[i]] = time_span[row]
                else:
                    one_row[header[i]] = full_data[i - 1][row]
            writer.writerow(one_row)
        csv_file.close()


def main():
    read_beginning_of_time()
    for mw in range(number_of_middlewares):
        current_mw = mw + 1
        for command_type in command_types:
            for cpt in virtual_clients_pt:
                for wt in worker_threads:
                    data_per_rep = []
                    for rep in range(repetitions):
                        print("MW = " + str(current_mw) + ", command = " + command_type + ", cpt = " + str(cpt) + ", wt = " + str(wt) + ", rep = " + str(rep))
                        data = read_csv(mw, command_type, cpt, wt, rep)
                        data_per_rep.append(data)
                    counters = [len(data_per_rep[0]), len(data_per_rep[1]), len(data_per_rep[2])]
                    max_allowed_cnt = np.min(counters)
                    # if max_allowed_cnt > 90:
                    #     max_allowed_cnt = 90
                    time_span = list(range(0, max_allowed_cnt))

                    header = ["#Time [s]", "Throughput [req/s] - rep1", "Throughput [req/s] - rep2",
                              "Throughput [req/s] - rep3"]
                    path = agg_path_base + "throughput_" + "mw" + str(current_mw) + "_cpt" + str(cpt) + \
                           "_wt" + str(wt) + \
                           command_type + ".csv"
                    print_csv(header, path, time_span, data_per_rep)

if __name__ == "__main__":
    main()
