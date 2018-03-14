"""
    ASL project - fall 2017

    author: Jovan Nikolic

    Processes json log file produced by memtiers
"""

from pathlib import Path
import numpy as np
import csv

# file_base_name = "data/baseline_nomidd_1server/"
# plot_base_name = "plots/baseline_nomidd_1server/"
file_base_name = "data/baseline_nomidd_2servers/"
plot_base_name = "plots/baseline_nomidd_2servers/"
ping_file_base = "ping_results_"
max_vms = 3


def process():
    min_rtts = []
    avg_rtts = []
    max_rtts = []
    mdev_rtts = []

    for i in range(1, max_vms + 1):
        path = file_base_name + ping_file_base + str(i) + ".txt"
        file = Path(path)

        if file.exists() and file.is_file():
            with open(path) as ping_file:
                ping_data = ping_file.readlines()
            ping_data = [x.strip() for x in ping_data]
            final_line = ping_data[len(ping_data)-1]
            # print(final_line)
            lhs, rhs = final_line.split(" = ", 1)
            rhs.strip()
            rhs.lstrip(' ')
            # print(rhs)
            just_numbers, msecs = rhs.split(" ", 1)
            just_numbers.strip()
            # print(just_numbers)
            min_rtt, rest = just_numbers.split("/", 1)
            # print(min_rtt)
            rest.strip()
            avg_rtt, rest = rest.split("/", 1)
            # print(avg_rtt)
            rest.strip()
            max_rtt, mdev_rtt = rest.split("/", 1)
            # print(max_rtt)
            # print(mdev_rtt)
            min_rtts.append(min_rtt)
            avg_rtts.append(avg_rtt)
            max_rtts.append(max_rtt)
            mdev_rtts.append(mdev_rtt)
        else:
            break

    min_overall = np.min(np.asarray(min_rtts, dtype=float))
    avg_overall = np.mean(np.asarray(avg_rtts, dtype=float))
    max_overall = np.max(np.asarray(max_rtts, dtype=float))
    mdev_overall = np.max(np.asarray(mdev_rtts, dtype=float))

    output_path = plot_base_name + "ping_results.csv"
    full_header = ["Min RTT", "Average RTT", "Max RTT", "MDev RTT"]

    with open(output_path, 'w') as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=full_header)
        writer.writeheader()

        writer.writerow({full_header[0]: min_overall,
                         full_header[1]: avg_overall,
                         full_header[2]: max_overall,
                         full_header[3]: mdev_overall})
        csv_file.close()


def main():
    process()


if __name__ == "__main__":
    main()
