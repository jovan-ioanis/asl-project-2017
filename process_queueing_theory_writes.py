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


path_base_sets = "data/experiment_write-only/middleware"
path_base_gets = "data/experiment_write-only/middleware"
agg_path_base = "aggregated_data/queueing_theory/"
client_threads_basename = "clientThreads_"
worker_threads_basename = "_workerThreads_"
counters_basename = "counter_"
timers_basename = "timers_"

number_of_middlewares = 2
clients_for_lambda = [32]
# virtual_clients_pt = [1, 5, 8, 15, 22, 28, 32, 42, 52, 64]
worker_threads = [8, 16, 32, 64]
command_types = ["_S1-G0"]
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
    return 1/shortest_service_time


def extract_mus():
    clients_for_mu = [5, 52, 64, 64]
    mus = {}
    for i, wt in enumerate(worker_threads):
        all_data = {}
        for mw in range(number_of_middlewares):
            all_data[mw] = {}
            current_mw = mw + 1
            for rep in range(repetitions):
                all_data[mw][rep] = read_one_experiment(current_mw, clients_for_mu[i], wt, rep, command_types[0])
        mus[wt] = get_mu(all_data, wt)
        print("For workers = " + str(wt) + " mu = " + str(mus[wt]) + " per service.")
    return mus


def get_lambda(all_data, wt):
    taus = {}
    for mw in range(number_of_middlewares):
        taus[mw] = {}
        for rep in range(repetitions):
            all_reqs = []
            for current_worker in range(wt):
                all_jobs = all_data[mw][rep][current_worker]
                all_reqs = np.concatenate([np.asarray(all_reqs), np.asarray(all_jobs)])

            sorted_rrt = sorted(all_reqs, key=lambda x: x.request_received_time, reverse=False)

            all_interarrival_times = []
            for i in range(len(sorted_rrt)):
                if i == 0:
                    continue
                interarrival_time = (sorted_rrt[i].request_received_time - sorted_rrt[i-1].request_received_time) / 1e9
                all_interarrival_times.append(interarrival_time)
            taus[mw][rep] = np.mean(np.asarray(all_interarrival_times))

    return taus


def extract_lambdas():
    client = 32

    lambdas = []
    for i, wt in enumerate(worker_threads):
        all_data = {}
        for mw in range(number_of_middlewares):
            all_data[mw] = {}
            current_mw = mw + 1
            for rep in range(repetitions):
                all_data[mw][rep] = read_one_experiment(current_mw, client, wt, rep, command_types[0])
        taus = get_lambda(all_data, wt)
        print("WT = " + str(wt) + "MW = 0, reps: " + str(1/taus[0][0]) + ", " + str(1/taus[0][1]) + ", " + str(1/taus[0][2]))
        print("WT = " + str(wt) + "MW = 1, reps: " + str(1/taus[1][0]) + ", " + str(1/taus[1][1]) + ", " + str(1/taus[1][2]))

        all_taus = []
        for mw in range(number_of_middlewares):
            for rep in range(repetitions):
                all_taus.append(taus[mw][rep])
        mean_tau = np.mean(np.asarray(all_taus))
        lambdas.append(1/mean_tau)

    return lambdas


def print_csv(path, mus, all_mus, all_lambdas):
    header = ["#Workers", "Service rate per thread", "Total service rate", "Lambda for 192 clients"]
    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(all_mus)):
            one_row = {}
            i = 0
            one_row[header[i]] = worker_threads[row]
            i += 1
            one_row[header[i]] = mus[worker_threads[row]]
            i += 1
            one_row[header[i]] = all_mus[row]
            i += 1
            one_row[header[i]] = all_lambdas[row]
            i += 1
            writer.writerow(one_row)
        csv_file.close()


def calc_p0():
    num_services = [2*8, 2*16, 2*32, 2*64]
    service_rate = [482.045499892, 371.117756628, 213.71715031, 135.839109625]
    lambdas = [7166.93041928, 10126.9956543, 11950.0996135, 14098.7146096]
    p0s = []
    probabilities_of_queueing = []
    ros = np.asarray(lambdas) / (np.asarray(num_services) * np.asarray(service_rate))
    for i in range(len(ros)):
        m = num_services[i]
        ro = ros[i]

        first_part = ((m * ro)**m)/(math.factorial(m) * (1 - ro))
        second_part = 0
        for n in range(1, m):
            second_part += ((m * ro)**n) / math.factorial(n)

        p0 = 1 / (1 + first_part + second_part)
        p0s.append(p0)

        poq = p0*((m*ro)**m)/(math.factorial(m)*(1-ro))
        probabilities_of_queueing.append(poq)
    print(p0s)
    print(probabilities_of_queueing)


def main():
    # mus = extract_mus()
    # lambdas = extract_lambdas()
    #
    # all_mus = [2*8*mus[8], 2*16*mus[16], 2*32*mus[32], 2*64*mus[64]]
    # all_lambdas = [2*lambdas[0], 2*lambdas[1], 2*lambdas[2], 2*lambdas[3]]
    #
    # path = agg_path_base + "mm_values.csv"
    # print_csv(path, mus, all_mus, all_lambdas)
    calc_p0()


if __name__ == "__main__":
    main()


