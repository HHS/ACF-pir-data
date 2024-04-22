import pyodbc, argparse, json, os, re
import pandas as pd

def main():
    parser = argparse.ArgumentParser(
        prog="pir-extract",
        description="Extract data from Access database and save to Excel files."
    )
    parser.add_argument('file_path')

    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())

    args = parser.parse_args()
    file_path = args.file_path
    dbq = f'DBQ={file_path};'

    # Connect to the Access database
    conn_str = (
        r'DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};' +
        dbq
    )
    cnxn = pyodbc.connect(conn_str)

    # Get a list of all tables
    cursor = cnxn.cursor()
    table_list = [row.table_name for row in cursor.tables(tableType='TABLE')]

    # Extract potential years from table names
    years = []
    for table in table_list:
        
        year = re.match(r"tbl(\d{2})", table)
        if year:
            year = year.group(1)
        else:
            continue
        if year.isdigit():
            years.append(year)
    years = list(set(years))

    # Create a new Excel writer object
    for year in years:
        current_table_list = [table for table in table_list if re.match(f"tbl{year}", table)]
        if int(year) <= 8:
            year_str = f"20{year}"
        else:
            year_str = f"19{year}"
        path = os.path.join("C:/Users/reggie.gilliard/repos/ACF-pir-data/data/", f"pir_export_{year_str}.xlsx")
        writer = pd.ExcelWriter(path, engine='xlsxwriter')

        # Loop through the list of tables and write each to a sheet in the Excel file
        for table in current_table_list:
            query = f"SELECT * FROM [{table}]"
            df = pd.read_sql(query, cnxn)
            # df = df.map(lambda x: x.encode('unicode_escape').decode('utf-8') if isinstance(x, str) else x)
            table = table[0:30:1]
            df.to_excel(writer, sheet_name=table, index=False)

        # Save the Excel file
        writer._save()

if __name__ == "__main__":
    main()