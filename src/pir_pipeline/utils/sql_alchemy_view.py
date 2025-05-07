"""This module defines functions to generate views using SQLAlchemy.

All code in this module is sourced from
https://github.com/sqlalchemy/sqlalchemy/wiki/Views
"""

import sqlalchemy as sa
from sqlalchemy.ext import compiler
from sqlalchemy.schema import DDLElement


class CreateView(DDLElement):
    """Class for creating a view"""

    def __init__(self, name, selectable):
        self.name = name
        self.selectable = selectable


class DropView(DDLElement):
    """Class for dropping a view"""

    def __init__(self, name):
        self.name = name


@compiler.compiles(CreateView)
def _create_view(element, compiler, **kw):
    """Define create view statement

    Args:
        element (_type_): SQLAlchemy object
        compiler (_type_): SQLAlchemy compiler

    Returns:
        str: Create view SQL statement
    """
    return "CREATE VIEW %s AS %s" % (
        element.name,
        compiler.sql_compiler.process(element.selectable, literal_binds=True),
    )


@compiler.compiles(DropView)
def _drop_view(element, compiler, **kw):
    """Define drop view statement

    Args:
        element: SQLAlchemy object
        compiler: SQLAlchemy compiler

    Returns:
        str: Drop view SQL statement
    """
    return "DROP VIEW %s" % (element.name)


def view_exists(ddl, target, connection, **kw):
    """Return true if a view does exist

    Args:
        ddl: Statement defining/identifying the view
        target: Table
        connection: Database connection

    Returns:
        bool: Boolean indicating whether the view exists
    """
    return ddl.name in sa.inspect(connection).get_view_names()


def view_doesnt_exist(ddl, target, connection, **kw):
    """Return true if a view does not exist

    Args:
        ddl: Statement defining/identifying the view
        target: Table
        connection: Database connection

    Returns:
        bool: Boolean indicating whether the view does not exist
    """
    return not view_exists(ddl, target, connection, **kw)


def view(name, metadata, selectable):
    """Create a view

    Args:
        name: Name of the view
        metadata: SQLAlchemy metadata object
        selectable: Statement defining the view

    Returns:
        Table: SQLAlchemy Table; the view.
    """
    t = sa.table(
        name,
        *(
            sa.Column(c.name, c.type, primary_key=c.primary_key)
            for c in selectable.selected_columns
        ),
    )
    t.primary_key.update(c for c in t.c if c.primary_key)

    sa.event.listen(
        metadata,
        "after_create",
        CreateView(name, selectable).execute_if(callable_=view_doesnt_exist),
    )
    sa.event.listen(
        metadata,
        "before_drop",
        DropView(name).execute_if(callable_=view_exists),
    )
    return t
