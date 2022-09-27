"""
Plot the memory use for the container.

"""

import datetime as dt
import matplotlib.pyplot as plt


def main(filename: str = "monitor_container.out"):
    with open(filename, "r") as f:
        lines = f.read().splitlines()

    times, mems = [], []
    for line in lines:
        parts = line.split(',')
        if len(parts) <= 4:
            continue
        time = dt.datetime.strptime(parts[0], "%Y/%m/%dT%H:%M:%S")
        mem = parts[3].split('/')[0].rstrip()
        if mem.endswith("MiB"):
            mem = float(mem[0:-3]) / 1024
        elif mem.endswith("GiB"):
            mem = float(mem[0:-3])
        else:
            print(f"Memory: {mem} unknown format")
            continue
        times.append(time)
        mems.append(mem)

    fig, ax = plt.subplots()
    ax.plot(times, mems)
    ax.set_xlabel("Time (UTC)")
    ax.set_ylabel("Memory use GiB")
    plt.show()


if __name__ == "__main__":
    main()
