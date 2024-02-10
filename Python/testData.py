import pandas as pd
import xlsxwriter

def genData(writer):

    response = []

    for section in ['A', 'B', 'C', 'D']:
        df = {
            0 : ['', 'Region', '2', '3'],
            1 : ['', 'State', '2', '3'],
            2 : ['', 'Grant Number', '2', '3'],
            3 : ['', 'Program Number', '2', '3'],
            4 : ['', 'Type', '2', '3'],
            5 : ['', 'Grantee', '2', '3'],
            6 : ['', 'Program', '2', '3'],
            7 : ['', 'City', '2', '3'],
            8 : ['', 'ZIP Code', '2', '3'],
            9 : ['', 'ZIP 4', '2', '3'],
            10 : ['Question Name' + section + '1', section + '.1', '2', '3'],
            11 : ['Question Name' + section + '2', section + '.2', '2', '3'],
            12 : ['Question Name' + section + '3', section + '.3', '2', '3'],
            13 : ['Question Name' + section + '4', section + '.4', '2', '3'],
            14 : ['Question Name' + section + '5', section + '.5', '2', '3'],
            15 : ['Question Name' + section + '6', section + '.6', '2', '3'],
            16 : ['Question Name' + section + '7', section + '.7', '2', '3'],
            17 : ['Question Name' + section + '8', section + '.8', '2', '3'],
            18 : ['Question Name' + section + '9', section + '.9', '2', '3'],
            19 : ['Question Name' + section + '10', 'N/A', '2', '3'],
        }
        
        response.append(df)
        df = pd.DataFrame(df)
        name = 'Section ' + section
        df.to_excel(writer, sheet_name = name, header = False, index = False)
        
    program = {}
    question = {}
    
    for df in response:
        pdf = {
            'Region' : df[0][2:],
            'Grant Number' : df[2][2:],
            'Program Number' : df[3][2:],
            'Program Type' : df[4][2:],
            'Grantee Name' : df[5][2:],
            'Program Name' : df[6][2:],
            'Program Agency Type' : ["T1", "T2"],
            'Program Agency Description' : ["D1", "D2"],
            'Program Address Line 1' : ["ADD1", "ADD2"],
            'Program Address Line 2' : ["", "ADD22"],
            'Program City' : df[7][2:],
            'Program State' : df[1][2:],
            'Program ZIP Code' : df[8][2:],
            'Program ZIP 4' : df[9][2:],
            'Program Main Phone Number' : ["P1", "P2"],
            'Program Main Email' : ["E1", "E2"]
        }
    
        q_numbers = filter(
            lambda x: x not in ['Region', 'State', 'Grant Number', 'Program Number', 'Type', 'Grantee', 'Program', 'City', 'ZIP Code', 'ZIP 4'], 
            [df[key][1] for key in df.keys()]
        )
        q_numbers = list(q_numbers)
        q_names = [df[key][0] for key in df.keys()][10:]
        
        qdf = {
            'Category' : ['CAT']*10,
            'Section' : [section]*10,
            'Subsection' : ['']*10,
            'Question Order' : list(range(0, 10)),
            'Question Number' : q_numbers,
            'Question Name' : q_names,
            'Type' : ['HS'] * 10,
            'Question Text' : ['Some question text'] * 10,
        }
        
        try:
            for key in pdf.keys():
                program[key] = program[key] + pdf[key]
            for key in qdf.keys():
                question[key] = question[key] + qdf[key]
        except:
            program = pdf
            question = qdf
    
    program = pd.DataFrame(program)
    program.to_excel(writer, sheet_name = "Program Details", index = False)
    
    question = pd.DataFrame(question)
    question.to_excel(writer, sheet_name = "Reference", index = False)
    
    return()

fnames = [
    "C:/OHS-Project-1/ACF-pir-data/tests/data/unprocessed/base_test_2008.xlsx",
    "C:/OHS-Project-1/ACF-pir-data/tests/data/unprocessed/base_test_2009.xlsx"
]

for fname in fnames:
    workbook = xlsxwriter.Workbook(fname)
    workbook.add_worksheet('Section A')
    workbook.close()
    writer = pd.ExcelWriter(fname, engine ='openpyxl', mode = 'a', if_sheet_exists='overlay')

    genData(writer)
    writer._save()