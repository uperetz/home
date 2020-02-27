from utils import ArgLess
from glob import glob
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import sys
import os


pwd = ArgLess(os.getcwd, verbose=True)
ls = ArgLess(os.listdir, verbose=True)
cd = os.chdir
