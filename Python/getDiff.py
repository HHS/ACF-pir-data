import pandas as pd
import xlsxwriter

base = pd.read_excel("C:/OHS-Project-1/ACF-pir-data/data_repository/base_test.xlsx", sheet_name = None, dtype =  object)
modified = pd.read_excel("C:/OHS-Project-1/ACF-pir-data/data_repository/modified_test_1.xlsx", sheet_name = None, dtype = object)

def calculateDiff(base, modified):
    diff_dict = {}
    
    for key in base.keys():
               
        base_sheet = base[key]
        mod_sheet = modified[key]
        i = 0
        indices = []
        
        # Check for differences in column names
        diff_colnames = base_sheet.columns != mod_sheet.columns

        # In section sheets, the first row must also be checked (column names are really question_name)
        if key.find('Section') != -1:
            diff_row = base_sheet.iloc[0] != mod_sheet.iloc[0]
            diff_colnames = [x or y for x, y in zip(list(diff_colnames), diff_row.to_list())]
            id_cols = ['Grant Number', 'Program Number', 'Type']
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
        value_diff = base_sheet.fillna("!!!") != mod_sheet.fillna("!!!")
        mod_sheet['diff'] = value_diff.agg(sum, axis = 1)
        if key.find('Section') != -1:
            mod_sheet['diff'][0] = 0
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

fname = "C:/OHS-Project-1/ACF-pir-data/tests/data/diff_test.xlsx"
workbook = xlsxwriter.Workbook(fname)
workbook.add_worksheet('Section A_column')
workbook.close()
writer = pd.ExcelWriter(fname, engine = 'openpyxl', mode = 'a', if_sheet_exists = 'overlay')
diff_dict = calculateDiff(base, modified)

for key in diff_dict.keys():
    df = pd.DataFrame(diff_dict[key])
    df.to_excel(writer, sheet_name = key, index = False)

writer._save()