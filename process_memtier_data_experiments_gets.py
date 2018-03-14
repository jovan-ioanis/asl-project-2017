"""
    ASL project - fall 2017

    author: Jovan Nikolic

    Processes json log file produced by memtiers
"""

import json
import numpy as np
import csv

plots_base_name = "plots/experiment_gets/"
big_output_path_base_name = "aggregated_data/experiment_gets/"
file_base_name = "data/experiment_gets/"
csv_file_name = "client_timings_"
json_file_base_name = "json_output_file_"
throughput_literal = "Ops/sec"
hits_literal = "Hits/sec"
latency_literal = "Latency"
msec_literal = "<=msec"
percentage_literal = "percent"

suffixes = ["sharded", "nonsharded"]

# experimental setup
memtier_vms = 3
memtier_instances_per_vm = 2
num_threads_per_instance = 1
virtual_clients_pt = 2
worker_threads = 64
repetitions = 3

num_keys = [1, 3, 6, 9]
titles = ["response_time", "25th", "50th", "75th", "90th", "99th"]
percentiles = [25.0, 50.0, 75.0, 90.0, 99.0]
metrics = ["mean", "std"]

tt = ["percent", "<=msec"]
runtime = 90

all_data = {}


def make_filename(instance, keys, rep, index, vm):
    chosen_suffix = suffixes[index]

    return file_base_name + json_file_base_name + "inst" + str(instance) + "_cpt" + str(virtual_clients_pt) + \
           "_wt" + str(worker_threads) + "_rep" + str(rep) + "_S0-G10" + "_vm" + str(vm) + "_" + \
           chosen_suffix + "_keys" + str(keys) + ".json"


def read_jsons():
    for s, suffix in enumerate(suffixes):
        all_data[suffix] = {}
        for keys in num_keys:
            all_data[suffix][keys] = {}
            for rep in range(repetitions):
                current_rep = rep + 1
                all_data[suffix][keys][rep] = {}
                for vm_id in range(1, memtier_vms + 1):
                    all_data[suffix][keys][rep][vm_id] = {}
                    for inst in range(1, memtier_instances_per_vm + 1):
                        path = make_filename(inst, keys, current_rep, s, vm_id)
                        with open(path) as json_file:
                            json_data = json.load(json_file)
                            all_data[suffix][keys][rep][vm_id][inst] = json_data
                            json_file.close()


def process_response_time_and_percentiles():
    full_data = {}

    for suffix in suffixes:
        full_data[suffix] = {}
        for keys in num_keys:
            full_data[suffix][keys] = {}
            for rep in range(repetitions):
                full_data[suffix][keys][rep] = {}

                resp_time = []
                p_25th = []
                p_50th = []
                p_75th = []
                p_90th = []
                p_99th = []

                for vm_id in range(1, memtier_vms + 1):
                    for inst in range(1, memtier_instances_per_vm + 1):
                        chosen_msecs = [0.0, 0.0, 0.0, 0.0, 0.0]
                        diffs = [10000, 10000, 10000, 10000, 10000]
                        resp_time.append(all_data[suffix][keys][rep][vm_id][inst]["ALL STATS"]["Gets"][latency_literal])

                        histogram = all_data[suffix][keys][rep][vm_id][inst]["ALL STATS"]["GET"]

                        for i in range(len(histogram)):
                            field = histogram[i]
                            for k, percentile in enumerate(percentiles):
                                if abs((int(field[percentage_literal]) - percentile)) < diffs[k]:
                                    diffs[k] = abs(int(field[percentage_literal]) - percentile)
                                    chosen_msecs[k] = field[msec_literal]

                        p_25th.append(chosen_msecs[0])
                        p_50th.append(chosen_msecs[1])
                        p_75th.append(chosen_msecs[2])
                        p_90th.append(chosen_msecs[3])
                        p_99th.append(chosen_msecs[4])
                        print(diffs)

                full_data[suffix][keys][rep][titles[0]] = np.mean(np.asarray(resp_time))
                full_data[suffix][keys][rep][titles[1]] = np.mean(np.asarray(p_25th))
                full_data[suffix][keys][rep][titles[2]] = np.mean(np.asarray(p_50th))
                full_data[suffix][keys][rep][titles[3]] = np.mean(np.asarray(p_75th))
                full_data[suffix][keys][rep][titles[4]] = np.mean(np.asarray(p_90th))
                full_data[suffix][keys][rep][titles[5]] = np.mean(np.asarray(p_99th))

    return full_data


def make_histograms():
    broken_at = []

    histograms = {}
    for suffix in suffixes:
        histograms[suffix] = {}
        for keys in num_keys:
            histograms[suffix][keys] = {}
            for rep in range(repetitions):
                histograms[suffix][keys][rep] = {}
                for vm_id in range(1, memtier_vms + 1):
                    histograms[suffix][keys][rep][vm_id] = {}
                    for inst in range(1, memtier_instances_per_vm + 1):
                        histograms[suffix][keys][rep][vm_id][inst] = {}

                        p = []
                        m = []
                        hist = all_data[suffix][keys][rep][vm_id][inst]["ALL STATS"]["GET"]
                        xput = float(all_data[suffix][keys][rep][vm_id][inst]["ALL STATS"]["Gets"][throughput_literal])
                        for i in range(len(hist)):
                            p.append(float(format(hist[i][tt[0]], '.2f')) * xput * runtime / 100)
                            m.append(float(format(hist[i][tt[1]], '.2f')))

                        buckets = []
                        requests = []

                        step = 0.1
                        start = 0
                        end = start + step
                        last_saved_jobs = 0
                        iter = 0
                        while True:

                            if round(m[iter], 2) == round(end, 2):
                                buckets.append(round(end, 2))
                                requests.append(p[iter] - last_saved_jobs)
                                last_saved_jobs = p[iter]
                                start = end
                                end = start + step
                            if round(m[iter], 2) > round(end, 2):
                                buckets.append(round(end, 2))
                                requests.append(0)
                                start = end
                                end = start + step
                            else:
                                iter += 1
                            if iter >= len(m) or round(m[iter], 2) >= 15:
                                broken_at.append(p[iter] * 100 / (xput * runtime))
                                break

                        print("Total requests: " + str(np.sum(np.asarray(requests))) +
                              " and via throughput: " + str(xput * runtime) +
                              " which is " + str((xput * runtime - np.sum(np.asarray(requests))) * 100 /(xput * runtime)) + "% off")
                        histograms[suffix][keys][rep][vm_id][inst][tt[0]] = requests
                        histograms[suffix][keys][rep][vm_id][inst][tt[1]] = buckets
    print(broken_at)

    hist_per_rep = {}
    for suffix in suffixes:
        hist_per_rep[suffix] = {}
        for keys in num_keys:
            hist_per_rep[suffix][keys] = {}
            for rep in range(repetitions):
                hist_per_rep[suffix][keys][rep] = {}
                hist_per_rep[suffix][keys][rep][tt[0]] = []
                for vm_id in range(1, memtier_vms + 1):
                    for inst in range(1, memtier_instances_per_vm + 1):
                        buckets = histograms[suffix][keys][rep][vm_id][inst][tt[1]]
                        requests = histograms[suffix][keys][rep][vm_id][inst][tt[0]]

                        if tt[1] not in hist_per_rep[suffix][keys][rep]:
                            hist_per_rep[suffix][keys][rep][tt[1]] = buckets
                        for k in range(len(requests)):
                            if k >= len(hist_per_rep[suffix][keys][rep][tt[0]]):
                                hist_per_rep[suffix][keys][rep][tt[0]].append(requests[k])
                            else:
                                hist_per_rep[suffix][keys][rep][tt[0]][k] += requests[k]

    print_hists_per_rep(hist_per_rep)

    final_buckets = hist_per_rep[suffixes[0]][num_keys[2]][1][tt[1]]
    hist_final = {}
    for suffix in suffixes:
        hist_final[suffix] = {}
        for keys in num_keys:
            hist_final[suffix][keys] = {}
            hist_final[suffix][keys][metrics[0]] = [] #mean
            hist_final[suffix][keys][metrics[1]] = [] #std

            for z in range(len(final_buckets)):
                points = [hist_per_rep[suffix][keys][0][tt[0]][z],
                          hist_per_rep[suffix][keys][1][tt[0]][z],
                          hist_per_rep[suffix][keys][2][tt[0]][z]]
                hist_final[suffix][keys][metrics[0]].append(np.mean(np.asarray(points)))
                hist_final[suffix][keys][metrics[1]].append(np.std(np.asarray(points)))

    print_final_hists(hist_final, final_buckets)


def print_final_hists(hist_final, final_buckets):
    header = ["#Buckets",
              "Mean jobs - Keys 1", "Std jobs - Keys 1",
              "Mean jobs - Keys 3", "Std jobs - Keys 3",
              "Mean jobs - Keys 6", "Std jobs - Keys 6",
              "Mean jobs - Keys 9", "Std jobs - Keys 9"]

    for suffix in suffixes:

        path = plots_base_name + "histograms_" + suffix + ".csv"
        with open(path, 'w') as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=header)
            writer.writeheader()

            for row in range(len(final_buckets)):
                one_row = {}
                i = 0
                one_row[header[i]] = final_buckets[row]
                i += 1
                for keys in num_keys:
                    for metric in metrics:
                        one_row[header[i]] = hist_final[suffix][keys][metric][row]
                        i += 1
                writer.writerow(one_row)
            csv_file.close()


def print_hists_per_rep(hist_per_rep):
    header = ["#Buckets",
              "Keys 1 - rep 1", "Keys 1 - rep 2", "Keys 1 - rep 3",
              "Keys 3 - rep 1", "Keys 3 - rep 2", "Keys 3 - rep 3",
              "Keys 6 - rep 1", "Keys 6 - rep 2", "Keys 6 - rep 3",
              "Keys 9 - rep 1", "Keys 9 - rep 2", "Keys 9 - rep 3"]

    for suffix in suffixes:

        path = big_output_path_base_name + "histograms_" + suffix + ".csv"
        buckets = hist_per_rep[suffix][9][1][tt[1]]

        with open(path, 'w') as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=header)
            writer.writeheader()

            for row in range(len(buckets)):
                one_row = {}
                i = 0
                one_row[header[i]] = buckets[row]
                i += 1
                for keys in num_keys:
                    for rep in range(repetitions):
                        one_row[header[i]] = hist_per_rep[suffix][keys][rep][tt[0]][row]
                        i += 1
                writer.writerow(one_row)
            csv_file.close()


def process_final(full_data):
    final_data = {}
    for suffix in suffixes:
        final_data[suffix] = {}
        for keys in num_keys:
            final_data[suffix][keys] = {}
            for title in titles:
                final_data[suffix][keys][title] = {}
                l1 = []
                for rep in range(repetitions):
                    l1.append(full_data[suffix][keys][rep][title])
                final_data[suffix][keys][title][metrics[0]] = np.mean(np.asarray(l1))
                final_data[suffix][keys][title][metrics[1]] = np.std(np.asarray(l1))

    return final_data


def print_final_data(index, final_data):
    header = ["#Keys",
              "Mean Response Time [ms]", "Std Response Time",
              "Mean 25th percentile [ms]", "Std 25th percentile",
              "Mean 50th percentile [ms]", "Std 50th percentile",
              "Mean 75th percentile [ms]", "Std 75th percentile",
              "Mean 90th percentile [ms]", "Std 90th percentile",
              "Mean 99th percentile [ms]", "Std 99th percentile"]

    path = plots_base_name + "response_time_and_percentiles_" + suffixes[index] + ".csv"

    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(num_keys)):
            one_row = {}
            i = 0
            one_row[header[i]] = num_keys[row]
            i += 1
            for title in titles:
                for metric in metrics:
                    one_row[header[i]] = final_data[suffixes[index]][num_keys[row]][title][metric]
                    i += 1
            writer.writerow(one_row)
        csv_file.close()


def print_csv_all_reps(index, full_data):
    header = ["#Keys"]
    for title in titles:
        for rep in range(repetitions):
            current_rep = rep + 1
            header.append(title + "_rep" + str(current_rep))

    path = big_output_path_base_name + "all_" + suffixes[index] + ".csv"

    with open(path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=header)
        writer.writeheader()

        for row in range(len(num_keys)):
            one_row = {}
            i = 0
            one_row[header[i]] = num_keys[row]
            i += 1
            for title in titles:
                for rep in range(repetitions):
                    one_row[header[i]] = full_data[suffixes[index]][num_keys[row]][rep][title]
                    i += 1
            writer.writerow(one_row)
        csv_file.close()


def main():
    read_jsons()
    make_histograms()
    # full_data = process_response_time_and_percentiles()
    # final_data = process_final(full_data)
    # for index in range(len(suffixes)):
    #     print_csv_all_reps(index, full_data)
    #     print_final_data(index, final_data)


if __name__ == "__main__":
    main()








