import os
import glob
import pandas as pd

folder = r"/Users/huiwenli/"
files = glob.glob(folder+"/data_30_*.csv")
#combine all files in the list
combined_csv = pd.concat([pd.read_csv(f) for f in files ])
#export to csv
combined_csv.to_csv( "ftx_fct_30.csv", index=False)
