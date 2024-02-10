import pandas as pd, sys, os
from diffWriter import diffWriter

def calculateDiff(base, modified):
    base = pd.read_excel(base, sheet_name = None, dtype =  object)
    modified = pd.read_excel(modified, sheet_name = None, dtype = object)

    diff_dict = {}
    
    for key in base.keys():
               
        base_sheet = base[key]
        mod_sheet = modified[key]
        
        if base_sheet.equals(mod_sheet):
            continue
        
        i = 0
        indices = []
        shared_cols = []
        # Check for differences in column names
        base_columns = list(base_sheet.columns)
        mod_columns = list(mod_sheet.columns)
        diff_colnames = [col not in base_columns for col in mod_columns]
        [shared_cols.append(col) for col in mod_columns if col in base_columns]

        # In section sheets, the first row must also be checked (column names are really question_name)
        if key.find('Section') != -1:
            base_columns = list(base_sheet.iloc[0])
            mod_columns = list(mod_sheet.iloc[0])
            diff_row = [col not in base_columns for col in mod_columns]
            diff_colnames = [x or y for x, y in zip(diff_colnames, diff_row)]
            id_cols = [
                "Region", "State", "Grant Number", "Program Number", 
                "Type", "Grantee", "Program", "City", "ZIP Code", "ZIP 4"
            ]
            cols = mod_sheet.iloc[0]
        else:
            cols = mod_sheet.columns
        # Some columns must be kept, handle that here
            if key.find('Program') != -1:
                id_cols = ['Grant Number', 'Program Number', 'Program Type']
                cols = mod_sheet.columns
            elif key.find('Reference') != -1:
                id_cols = ['Question Number', 'Question Name']
        
        for col in cols:
            if col in id_cols:
                indices.append(i)
            i += 1
            
        diff_colnames = pd.Series(diff_colnames)
        for ind in indices:
            diff_colnames.iloc[ind] = True
        
        column_diff = mod_sheet.loc[:, diff_colnames.to_list()]
        
        # Check for value differences
        
        try:
            value_diff = base_sheet[shared_cols].fillna("!!!") != mod_sheet[shared_cols].fillna("!!!")
        except:
            diff_dict[key] = mod_sheet
            continue
        
        mod_sheet['diff'] = value_diff.agg(sum, axis = 1)
        if key.find('Section') != -1:
            # Since Section first row is col names, it is handled with column_diff
            mod_sheet.loc[0, 'diff'] = 0
        value_diff = mod_sheet[mod_sheet['diff'] == 1]
        value_diff = value_diff.drop('diff', axis = 1)
        
        # Save the differences to a dictionary
        for difference in ['column', 'value']:
            diff_output = locals()[difference + "_diff"]
            if diff_output.empty:
                diff_output_trunc = diff_output
            elif key.find('Section') != -1 and difference == 'column':
                diff_output_trunc = diff_output.drop(diff_output.columns[[0, 1, 2]], axis = 1)
            elif key.find('Section') == -1:
                diff_output_trunc = diff_output.drop(id_cols, axis = 1)
                
            if diff_output_trunc.any().any():
                diff_dict[key + '_' + difference] = diff_output
            else:
                pass
    
    return(diff_dict)

paths = sys.argv[1:]
if len(paths) > 2:
    raise ValueError("Too many arguments provided.")

# base_path = paths[0]
# mod_path = paths[1]
base_path = r"C:\OHS-Project-1\ACF-pir-data\tests\data\processed\base_test_2009_20240124.xlsx"
mod_path = r"C:\OHS-Project-1\ACF-pir-data\tests\data\unprocessed\base_test_2009.xlsx"
writer = diffWriter(mod_path)
diff_dict = calculateDiff(base_path, mod_path)

if diff_dict:
    for key in diff_dict.keys():
        df = pd.DataFrame(diff_dict[key])
        df.to_excel(writer.writer, sheet_name = key, index = False)
    del writer.writer.book['Sheet1']
    writer.writer._save()
else:
    writer.writer.close()
    os.remove(writer.out_path)