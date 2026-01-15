"""SQLAlchemy models for creating and interacting with the PIR database"""

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKeyConstraint,
    Integer,
    MetaData,
    String,
    Table,
    Text,
    UniqueConstraint,
    and_,
    distinct,
    func,
    literal_column,
    null,
    or_,
    select,
)
from sqlalchemy.dialects.postgresql.json import JSONB

from pir_pipeline.utils.sql_alchemy_view import view

# Taken from https://docs.sqlalchemy.org/en/20/core/constraints.html#constraint-naming-conventions
# Defining constraint naming conventions
convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}
sql_metadata = MetaData(naming_convention=convention)


program = Table(
    "program",
    sql_metadata,
    Column("uid", String(255), primary_key=True, index=True),
    Column("year", Integer, primary_key=True, index=True),
    Column("grantee_name", String(255)),
    Column("grant_number", String(255)),
    Column("program_address_line_1", String(255)),
    Column("program_address_line_2", String(255)),
    Column("program_agency_description", String(255)),
    Column("program_agency_type", String(255)),
    Column("program_city", String(255)),
    Column("program_email", String(255)),
    Column("program_name", String(255)),
    Column("program_number", String(255)),
    Column("program_phone", String(255)),
    Column("program_type", String(255)),
    Column("program_state", String(255)),
    Column("program_zip1", String(255)),
    Column("program_zip2", String(255)),
    Column("region", Integer),
)

question = Table(
    "question",
    sql_metadata,
    Column("question_id", String(255), primary_key=True, index=True),
    Column("year", Integer, primary_key=True, index=True),
    Column("uqid", String(255)),
    Column("category", String(255)),
    Column("question_name", Text),
    Column("question_number", String(255)),
    Column("question_order", Float),
    Column("question_text", Text),
    Column("question_type", String(255)),
    Column("section", String(255)),
    Column("subsection", String(255)),
    UniqueConstraint("uqid", "year"),
)

response = Table(
    "response",
    sql_metadata,
    Column("uid", String(255), primary_key=True, index=True),
    Column("question_id", String(255), primary_key=True, index=True),
    Column("year", Integer, primary_key=True, index=True),
    Column("answer", Text),
    ForeignKeyConstraint(
        ["uid", "year"],
        ["program.uid", "program.year"],
        onupdate="CASCADE",
        ondelete="CASCADE",
    ),
    ForeignKeyConstraint(
        ["question_id", "year"],
        ["question.question_id", "question.year"],
        onupdate="CASCADE",
        ondelete="CASCADE",
    ),
)

uqid_changelog = Table(
    "uqid_changelog",
    sql_metadata,
    Column("id", Integer, primary_key=True),
    Column("timestamp", DateTime(timezone=True), default=func.now()),
    Column("question_id", String(255), index=True),
    Column("original_uqid", String(255), index=True),
    Column("new_uqid", String(255)),
    Column("complete_series_flag", Integer, default=0),
)

proposed_changes = Table(
    "proposed_changes",
    sql_metadata,
    Column("id", String(255), primary_key=True),
    Column("link_dict", JSONB),
    Column("html", Text),
)

# Here to proposed_ids definition written with GPT
dictionaries = (
    func.jsonb_array_elements(proposed_changes.c.link_dict)
    .table_valued("value")
    .alias("dictionaries")
)

link_dicts = (
    select(dictionaries.c.value.label("value"))
    .select_from(proposed_changes)
    .join(dictionaries, literal_column("true"))  # CROSS JOIN LATERAL
    .subquery("link_dicts")
)

dict_values = (
    func.jsonb_each_text(link_dicts.c.value).table_valued("key", "value").alias("lvl2")
)

proposed_ids = (
    select(distinct(dict_values.c.value))
    .select_from(link_dicts)
    .join(dict_values, literal_column("true"))  # CROSS JOIN LATERAL
    .where(dict_values.c.key == "base_question_id")
    .scalar_subquery()
)

# Confirmed records should be excluded
confirmed_subquery = (
    select(uqid_changelog.c["original_uqid"])
    .group_by(uqid_changelog.c["original_uqid"])
    .having(func.max(uqid_changelog.c["complete_series_flag"]) == 1)
    .scalar_subquery()
)

# Unlinked view
query = select(question).where(question.c.uqid.is_(None))
unlinked = view("unlinked", sql_metadata, query)

# Linked view
query = select(question).where(question.c.uqid.is_not(None))
linked = view("linked", sql_metadata, query)

# Confirmed view
query = (
    select(question)
    .where(question.c.uqid.in_(confirmed_subquery))
    .distinct()
    .order_by(question.c.year, question.c.question_number)
)

confirmed = view("confirmed", sql_metadata, query)

# Unconfirmed view
confirmed_subquery = select(confirmed.c["uqid"])
query = (
    select(question)
    .where(or_(question.c.uqid.not_in(confirmed_subquery), question.c.uqid == null()))
    .distinct()
    .order_by(question.c.year, question.c.question_number)
)

unconfirmed = view("unconfirmed", sql_metadata, query)

# Flashcard view
query = (
    select(question)
    .where(
        or_(
            and_(
                question.c.uqid.not_in(confirmed_subquery),
                question.c.question_id.not_in(proposed_ids),
            ),
            question.c.uqid == null(),
        )
    )
    .distinct()
    .order_by(question.c.year, question.c.question_number)
)

flashcard = view("flashcard", sql_metadata, query)
