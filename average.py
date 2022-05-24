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

cycle_rows = [['benchmark', 'average cycles']]
instret_rows = [['benchmark', 'average instret']]

os.chdir(args.folder)
path = os.getcwd()
print(path)
walk = os.walk(path)
for path, subdirs, files in walk:
    for name in files:
        if "cycle" in name or "instret" in name:
            n, _ = os.path.splitext(name)
            n = n.split('-')
            type_name = n[1]
            app = n[2]
            p = path.split('/')
            benchmark = '/'.join(p[5:8]) + '/' + app
            cur_path = os.path.join(path, name)
            if cur_path.endswith(ext):
                print(benchmark)
                csvread = pd.read_csv(cur_path, names=['core',type_name])
                column = csvread[type_name].to_numpy()
                avg = np.average(column).astype(int)
                print("avg: ", avg)
                if type_name == "cycle":
                    cycle_rows.append([benchmark, avg])
                elif type_name == "instret":
                    instret_rows.append([benchmark, avg])
                    
# Combine 2D arrays
cycles = pd.DataFrame(cycle_rows[1:], columns=cycle_rows[0])
instret = pd.DataFrame(instret_rows[1:], columns=instret_rows[0])
data = pd.merge(cycles, instret, on=['benchmark'])
print(data)
            
# Write to csv
data.to_csv('results.csv', index=False)