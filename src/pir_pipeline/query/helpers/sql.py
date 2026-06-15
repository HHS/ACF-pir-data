"""Routes and logic for the home page"""

from sqlalchemy import CTE, and_, bindparam, func, or_, select

from pir_pipeline.utils.SQLAlchemyUtils import SQLAlchemyUtils


def get_qids(db: SQLAlchemyUtils, data: list[dict]) -> dict[str, list]:
    question_table = db.tables["question"]

    uqids = []
    question_ids = []
    for item in data:
        condition = [question_table.c[key] == bindparam(key) for key in item]

        uqid_query = select(func.distinct(question_table.c["uqid"])).where(
            and_(*condition)
        )
        question_id_query = select(
            func.distinct(question_table.c["question_id"])
        ).where(and_(*condition))

        uqid = db.get_scalar(uqid_query, item)
        if uqid:
            uqids.append(uqid)

        question_id = db.get_scalar(question_id_query, item)
        if question_id:
            question_ids.append(question_id)

    id_dict = {"question_id": list(set(question_ids)), "uqid": list(set(uqids))}

    return id_dict


def question_cte(db: SQLAlchemyUtils, data: dict[str, list]) -> CTE:
    question_table = db.tables["question"]
    qids = get_qids(db, data["question"])
    data.update({"question": qids})
    condition = [question_table.c[key].in_(bindparam(key)) for key in qids]
    query = select(question_table).where(or_(*condition)).cte()

    return query


def program_cte(db: SQLAlchemyUtils, data: dict[str, dict[str, list]]) -> CTE:
    program_data = data["program"]
    program_table = db.tables["program"]
    condition = [program_table.c[key].in_(bindparam(key)) for key in program_data]
    query = select(program_table).where(and_(*condition)).cte()

    return query


def get_responses(db: SQLAlchemyUtils, data: dict[str, dict]) -> list[dict]:
    response_table = db.tables["response"]
    program = program_cte(db, data)
    question = question_cte(db, data)
    program_vars = tuple(
        [var.name for var in program.c if var.name not in ["year", "uid"]]
    )
    question_vars = tuple(
        [var.name for var in question.c if var.name not in ["year", "question_id"]]
    )
    query = (
        select(
            response_table,
            program.c[program_vars],
            question.c[question_vars],
        )
        .join(
            program,
            and_(
                response_table.c.uid == program.c.uid,
                response_table.c.year == program.c.year,
            ),
        )
        .join(
            question,
            and_(
                response_table.c.question_id == question.c.question_id,
                response_table.c.year == question.c.year,
            ),
        )
    )

    params = {key: value for item in data.values() for key, value in item.items()}
    records = []
    with db._engine.connect() as conn:
        result = conn.execute(query, params)
        description = result.cursor.description
        for value in result.fetchall():
            records.append({description[i].name: value[i] for i in range(len(value))})

    return records
