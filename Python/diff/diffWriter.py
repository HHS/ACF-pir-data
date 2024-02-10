import xlsxwriter, re, pandas as pd

class diffWriter:
    def __init__(self, path):
        path_match = re.match(r"(.+)(?<=\\|\/)(\w+\.\w+)$", path)
        file_name = path_match.groups()[1]
        file_name_new = "diff_" + file_name
        diff_name = path_match.groups()[0] + file_name_new

        workbook = xlsxwriter.Workbook(diff_name)
        workbook.close()
        writer = pd.ExcelWriter(diff_name, engine = 'openpyxl', mode = 'a', if_sheet_exists = 'overlay')
        self.writer = writer
        self.out_path = diff_name