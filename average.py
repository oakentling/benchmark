#!/usr/bin/env python3

import os
import pandas as pd
import numpy as np
import argparse
import csv

ext = ('.csv')

parser = argparse.ArgumentParser()
parser.add_argument(
    '--folder',
    '-f',
    help='Name of the results folder with traces to be averaged.'
)
args = parser.parse_args()

rows = [['benchmark', 'average cycles']]

os.chdir(args.folder)
path = os.getcwd()
print(path)
walk = os.walk(path)
for path, subdirs, files in walk:
    for name in files:
        if name != "results.csv":
            cur_path = os.path.join(path, name)
            if cur_path.endswith(ext):
                print(cur_path)
                csvread = pd.read_csv(cur_path, header=0, names=['core','cycles'])
                column = csvread['cycles'].to_numpy()
                avg = np.average(column).astype(int)
                print("avg: ", avg)
                rows.append([cur_path, avg])
            
# Prepare csv writer
filename = "results.csv"
with open(filename, 'w') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerows(rows)