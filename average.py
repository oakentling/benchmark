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

cycle_rows = [['config', 'sim', 'variation', 'app', 'post', 'average cycles']]
instret_rows = [['config', 'sim', 'variation', 'app', 'post', 'average instret']]

os.chdir(args.folder)
path = os.getcwd()
print(path)
walk = os.walk(path)
for path, subdirs, files in walk:
    for name in files:
        if "cycle" in name or "instret" in name:
            n, _ = os.path.splitext(name)
            n = n.split('-')
            print(n)
            var = n[1]
            app = n[2]
            post = 0
            if 3 < len(n):
                post = 1
                app = app + "-post"
            print("app: ", app, "post: ", post)
            p = path.split('/')
            config = p[5]
            sim = p[6]
            variation = p[7]
            cur_path = os.path.join(path, name)
            print("app: ", app)
            if cur_path.endswith(ext):
                print(cur_path)
                print('/'.join([config, sim, variation, app]))
                csvread = pd.read_csv(cur_path, names=['core',var])
                column = csvread[var].to_numpy()
                avg = np.average(column).astype(int)
                print("avg: ", avg)
                if var == "cycle":
                    cycle_rows.append([config, sim, variation, app, post, avg])
                elif var == "instret":
                    instret_rows.append([config, sim, variation, app, post, avg])
                    
# Combine 2D arrays
print(cycle_rows)
cycles = pd.DataFrame(cycle_rows[1:], columns=cycle_rows[0])
instret = pd.DataFrame(instret_rows[1:], columns=instret_rows[0])
data = pd.merge(cycles, instret, on=['config', 'sim', 'variation', 'app', 'post'])
print(data)
            
# Write to csv
data.to_csv('results.csv', index=False)