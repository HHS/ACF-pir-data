import pandas as pd
import copy

ingested = pd.read_excel("C:/OHS-Project-1/ACF-pir-data/data_repository/pir_export_2008.xls", sheet_name = None, header = None)
modified = copy.deepcopy(ingested)

for key in ingested.keys()
modified['Section A'].loc[1, 1] = None
diff = ingested['Section A'].fillna("!!!") != modified['Section A'].fillna("!!!")
ingested['Section A']['diff'] = diff.agg(sum, axis = 1)
diff = ingested['Section A'][ingested['Section A']['diff'] == 1]
diff.drop('diff', axis = 1)
print(diff)