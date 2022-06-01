#!/usr/bin/env python3

import os
import pandas as pd
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import argparse
import csv

parser = argparse.ArgumentParser()
parser.add_argument(
    '--folder',
    '-f',
    help='Name of the results folder with traces to be averaged.'
)
args = parser.parse_args()
os.chdir(args.folder)
path = os.getcwd()
print(path)

data = np.genfromtxt('results.csv', skip_header=1, names=True, 
                     dtype=None, delimiter=',')
print(data.dtype)