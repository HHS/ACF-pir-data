"""SQLAlchemy models for creating and interacting with the PIR database"""

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKeyConstraint,
    Integer,
    MetaData,
    String,
    Table,
    Text,
    and_,
    func,
    select,
)

from pir_pipeline.utils.sql_alchemy_view import view

# Taken from https://docs.sqlalchemy.org/en/20/core/constraints.html#constraint-naming-conventions
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
    Column("complete_series_flag", Boolean, default=False),
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
linked = view(
    "linked", sql_metadata, select(question).where(question.c.uqid.is_not(None))
)

# Intermittent link view
year_query = select(func.count(func.distinct(question.c.year))).scalar_subquery()
uqid_query = (
    select(question.c.uqid)
    .group_by(question.c.uqid)
    .having(func.count(question.c.uqid) < year_query)
)
query = (
    select(question)
    .where(
        and_(
            question.c.uqid.in_(uqid_query), question.c.uqid.not_in(confirmed_subquery)
        )
    )
    .distinct()
)

intermittent = view("intermittent", sql_metadata, query)

# Inconsistent link view
subquery = select(linked.c.question_id, linked.c.uqid).distinct().subquery()
right = (
    select(subquery.c.uqid)
    .group_by(subquery.c.uqid)
    .having(func.count(subquery.c.question_id) > 1)
    .subquery()
)
query = (
    select(linked)
    .join(right, linked.c.uqid == right.c.uqid)
    .distinct()
    .where(question.c.uqid.not_in(confirmed_subquery))
)

inconsistent = view("inconsistent", sql_metadata, query)

# Confirmed view
query = (
    select(question)
    .where(question.c.uqid.in_(confirmed_subquery))
    .distinct()
    .order_by(question.c.year, question.c.question_number)
)

confirmed = view("confirmed", sql_metadata, query)

# Unconfirmed view
query = (
    select(question)
    .where(question.c.uqid.not_in(confirmed_subquery))
    .distinct()
    .order_by(question.c.year, question.c.question_number)
)

unconfirmed = view("unconfirmed", sql_metadata, query)
