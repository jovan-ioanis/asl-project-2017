"""
     ASL project - fall 2017

        author: Jovan Nikolic

        Processes logs generated by middleware
"""
import numpy as np
import csv
import math


class TimerStruct:
    def __init__(self):
        self.worker_id = -1
        self.command = "none"
        self.number_of_keys = -1
        self.queue_size = -1
        self.request_received_time = -1
        self.put_in_queue_time = -1
        self.taken_out_of_queue_time = -1
        self.sent_to_server_time = -1
        self.received_complete_response_time = -1
        self.response_sent_to_client_time = -1
        self.dump_to_disk_flag = -1


path_base_sets = "data/baseline_1midd/middleware"
path_base_gets = "data/baseline_1midd/middleware"
agg_path_base = "aggregated_data/queueing_theory/"
client_threads_basename = "clientThreads_"
worker_threads_basename = "_workerThreads_"
counters_basename = "counter_"
timers_basename = "timers_"

number_of_middlewares = 1
worker_threads = [8, 16, 32, 64]
command_types = ["_S1-G0", "_S0-G1"]
repetitions = 3
step = 1e9


def read_one_experiment(current_mw, client_thread, worker_thread, rep, command_type):
    if command_type == command_types[0]:
        command = "SET"
        base_p = path_base_sets
    else:
        command = "GET"
        base_p = path_base_gets

    raw_data = {}

    base_path = base_p + str(current_mw) + "/" + \
                client_threads_basename + str(client_thread) + \
                worker_threads_basename + str(worker_thread) + \
                command_type + \
                "_rep" + str(rep + 1) + "/logs/"

    for current_num_workers in range(worker_thread):
        path = base_path + timers_basename + str(current_num_workers) + ".log"
        raw_data[current_num_workers] = []

        with open(path, 'r') as timer_file:
            timer_data = timer_file.readlines()
            if len(timer_data) == 0:
                print(" Missing data for: cpt = " + str(client_thread) + ", wt = " + str(worker_thread) + ", rep = " + str(rep))
                continue
            timer_data = [x.strip() for x in timer_data]
            for k, line in enumerate(timer_data):
                if k == 0:
                    continue
                parsed_line = line.split(',')
                [x.strip() for x in parsed_line]
                ts = TimerStruct()
                ts.worker_id = int(parsed_line[0])
                ts.command = parsed_line[1]
                ts.number_of_keys = int(parsed_line[2])
                ts.queue_size = int(parsed_line[3])
                ts.request_received_time = int(parsed_line[4])
                ts.put_in_queue_time = int(parsed_line[5])
                ts.taken_out_of_queue_time = int(parsed_line[6])
                ts.sent_to_server_time = int(parsed_line[7])
                ts.received_complete_response_time = int(parsed_line[8])
                ts.response_sent_to_client_time = int(parsed_line[9])
                ts.dump_to_disk_flag = int(parsed_line[10])

                raw_data[current_num_workers].append(ts)

    return raw_data


def get_mu(all_data, wt):
    shortest_service_time = 100000
    for mw in range(number_of_middlewares):
        for rep in range(repetitions):
            for current_worker in range(wt):
                all_jobs = all_data[mw][rep][current_worker]
                service_times = []
                for job in all_jobs:
                    service_time = (job.response_sent_to_client_time - job.taken_out_of_queue_time) / 1e9
                    service_times.append(service_time)
                avg_sst = np.mean(np.asarray(service_times))
                shortest_service_time = min(avg_sst, shortest_service_time)
    return shortest_service_time


def get_nt(all_data, wt):
    shortest_service_time = 100000
    for mw in range(number_of_middlewares):
        for rep in range(repetitions):
            for current_worker in range(wt):
                all_jobs = all_data[mw][rep][current_worker]
                service_times = []
                for job in all_jobs:
                    service_time = (job.put_in_queue_time - job.request_received_time) / 1e9
                    service_times.append(service_time)
                avg_sst = np.mean(np.asarray(service_times))
                shortest_service_time = min(avg_sst, shortest_service_time)
    return shortest_service_time


def extract_mus():
    clients_for_mu = {command_types[0]: [42, 52, 52, 52],
                      command_types[1]: [42, 32, 64, 64]}

    mus = {}
    nt = {}
    for command_type in command_types:
        print("COMMAND TYPE = " + command_type)
        mus[command_type] = {}
        nt[command_type] = {}
        for i, wt in enumerate(worker_threads):
            all_data = {}
            for mw in range(number_of_middlewares):
                all_data[mw] = {}
                current_mw = mw + 1
                for rep in range(repetitions):
                    all_data[mw][rep] = read_one_experiment(current_mw, clients_for_mu[command_type][i], wt, rep, command_type)
            mus[command_type][wt] = get_mu(all_data, wt)
            nt[command_type][wt] = get_nt(all_data, wt)
            print("For workers = " + str(wt) + " mu = " + str(mus[command_type][wt]) + " nt = " + str(nt[command_type][wt]) + " per service.")
    return mus


def main():
    extract_mus()


if __name__ == "__main__":
    main()

