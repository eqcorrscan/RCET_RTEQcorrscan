"""
Build a csv of detection times and when detected from file properties.

"""

import os
import glob
import tqdm

from obspy import read_events
from datetime import datetime


def main(
    detection_dir: str,
    outfile: str,
    run_start: datetime = None,
    speedup: float = 1,
    mad_value: float = 8.,
):
    det_files = sorted(glob.glob(f"{detection_dir}/*/*/*.xml"))
    dets = []
    for det_file in tqdm.tqdm(det_files):
        mtime = os.path.getctime(det_file)
        # Convert to useful string
        mtime = datetime.fromtimestamp(mtime)
        ev = read_events(det_file)[0]
        template = [c for c in ev.comments if "Template: " in c.text][0].text.split("Template: ")[-1]
        threshold = float([c for c in ev.comments if "threshold=" in c.text][0].text.split("threshold=")[-1])
        detect_val = float([c for c in ev.comments if "detect_val=" in c.text][0].text.split("detect_val=")[-1])
        try:
            ori = ev.preferred_origin() or ev.origins[-1]
        except IndexError:
            print(f"No origin for {det_file}")
            ori = None
        if ori:
            ori_time = ori.time
            lat, lon, depth = ori.latitude, ori.longitude, ori.depth / 1000.
        else:
            ori_time, lat, lon, depth = "NaN", "NaN", "NaN", "NaN"
        dets.append((mtime, ori_time, lat, lon, depth, template, threshold, detect_val))

    if run_start is None:
        config_file = glob.glob(f"{detection_dir}/../../rt_eqcorrscan_config.yml")
        if len(config_file):
            run_start = os.path.getctime(config_file[0])
            run_start = datetime.fromtimestamp(run_start)
        else:
            run_start = min(d[0] for d in dets)
    run_times = [(d[0] - run_start).total_seconds() * speedup for d in dets]

    det_strings = []
    for det, rt in zip(dets, run_times):
        det_str = [
            det[0].strftime("%Y/%m/%d %H:%M:%S"),
            det[1].strftime("%Y/%m/%d %H:%M:%S"),
            str(det[2]),
            str(det[3]),
            str(det[4]),
            det[5],
            str(det[6]),
            str(det[7]),
            str(rt)
        ]
        if mad_value:
            det_str.append(str(det[7] / (det[6] / mad_value)))
        det_strings.append(det_str)

    det_string = "\n".join([", ".join(d) for d in det_strings])
    with open(outfile, "w") as f:
        f.write("Time created, Origin time, Latitude, Longitude, Depth (km), Template, Threshold, Correlation Sum, Run time(s)")
        if mad_value:
            f.write(", MAD Value")
        f.write("\n")
        f.write(det_string)

    return




if __name__ == "__main__":
    import argparse

    outfile = "Eketahuna_detections.csv"
    detection_dir = "detections/2014p051675/2014p051675/detections"

    parser = argparse.ArgumentParser()
    parser.add_argument("-o", "--outfile", type=str, default=outfile)
    parser.add_argument("-d", "--detection-dir", type=str, default=detection_dir)
    parser.add_argument("-s", "--speedup", type=float, default=1)
    parser.add_argument("-m", "--mad-value", type=float, default=8)
    parser.add_argument("-r", "--run-start", type=datetime, required=False)

    args = parser.parse_args()

    main(detection_dir=args.detection_dir, outfile=args.outfile,
         run_start=args.run_start, speedup=args.speedup,
         mad_value=args.mad_value)
