"""
Make some simple plots to check events.
"""

import glob
import os
import tqdm
import matplotlib.pyplot as plt

from typing import List

from obspy import read_events
from obspy.clients.fdsn import Client

from cjc_utilities.plot_event.plot_event import plot_event_from_client


def main(event_files: List[str], outpath: str):
    client = Client("GEONET")

    for event_file in tqdm.tqdm(event_files):
        out = f"{outpath}/{os.path.splitext(os.path.basename(event_file))[0]}.png"
        if os.path.isfile(out):
            continue
        ev = read_events(event_file)[0]
        fig = plot_event_from_client(
            event=ev, client=client, all_channels=True, filt=(2.0, 10.0))
        ori = ev.preferred_origin() or ev.origins[-1]
        fig.suptitle(
            f"{ori.latitude:.2f} {ori.longitude:.2f} {ori.depth / 1000:.1f} km")
        fig.savefig(out)
        plt.close(fig)
    return


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Plot some events")

    parser.add_argument("-i", "--inpath", help="Path to look for .xml files",
                        type=str, required=True)
    parser.add_argument("-o", "--outpath", help="Path to put figures into",
                        type=str, required=True)

    args = parser.parse_args()

    event_files = glob.glob(f"{args.inpath}/*.xml")
    main(event_files=sorted(event_files), outpath=args.outpath)
