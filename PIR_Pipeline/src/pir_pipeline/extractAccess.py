import pyodbc, argparse, json, os, re, shutil
import pandas as pd

def main():
    # Parse the command line arguments
    parser = argparse.ArgumentParser(
        prog="pir-extract",
        description="Extract data from Access database and save to Excel files."
    )
    parser.add_argument('file_path')

    # Load the configuration file
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_json = os.path.join(current_dir, "config.json")
    config = open(config_json)
    config = json.loads(config.read())

    # Connect to the Access database
    args = parser.parse_args() # Get command line arguments
    file_path = args.file_path
    dbq = f'DBQ={file_path};'

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
        # Extract the year from the table name if possible
        year = re.match(r"tbl(\d{2})", table)
        if year:
            year = year.group(1)
        else:
            continue
        if year.isdigit():
            years.append(year)
    # Get unique years
    years = list(set(years))

    # Loop through the years and extract the data to Excel files
    for year in years:
        # Get a list of tables for the current year
        current_table_list = [table for table in table_list if re.match(f"tbl{year}", table)]
        # Create the year to be appended to the file name
        if int(year) < 8:
            year_str = f"20{year}"
        elif int(year) == 8:
            continue
        else:
            year_str = f"19{year}"
        
        # Create the path for the Excel file
        path = os.path.join(config["Raw"], f"pir_export_{year_str}.xlsx")
        # Create a new Excel writer object
        writer = pd.ExcelWriter(path, engine='xlsxwriter')

        # Loop through the list of tables and write each to a sheet in the Excel file
        for table in current_table_list:
            query = f"SELECT * FROM [{table}]"
            df = pd.read_sql(query, cnxn)
            table = table[0:30:1] # Limit the table name to 30 characters
            df.to_excel(writer, sheet_name=table, index=False)

        # Save the Excel file
        writer._save()

    # If the file is in the Raw directory, move it to the Processed directory
    if os.path.normpath(config["Raw"]) in os.path.normpath(file_path):
        shutil.move(file_path, os.path.join(config["Processed"], os.path.basename(file_path)))
    else:
        # Copy the file to the Processed directory
        shutil.copy(file_path, os.path.join(config["Processed"], os.path.basename(file_path)))

if __name__ == "__main__":
    main()