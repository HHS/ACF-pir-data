from urllib.parse import quote_plus

from sqlalchemy import MetaData, Table, create_engine

from pir_pipeline.config import db_config

engine = create_engine(
    f"mysql+mysqlconnector://{db_config["user"]}:{quote_plus(db_config["password"])}@{db_config["host"]}:{db_config["port"]}/pir"
)

# Get classes
sql_metadata = MetaData()

response = Table("response", sql_metadata, autoload_with=engine)
program = Table("program", sql_metadata, autoload_with=engine)
question = Table("question", sql_metadata, autoload_with=engine)
unlinked = Table("unlinked", sql_metadata, autoload_with=engine)
linked = Table("linked", sql_metadata, autoload_with=engine)
