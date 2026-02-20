"""create_linker_table

Revision ID: 3f4dce7266b1
Revises:
Create Date: 2026-02-20 09:23:02.062061

"""

from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql.json import JSONB

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "3f4dce7266b1"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        "link_history",
        sa.Column("link_id", sa.String(255), nullable=False, primary_key=True),
        sa.Column("user", sa.String(255), nullable=False),
        sa.Column("link_dict", JSONB),
        sa.Column("link_timestamp", sa.DateTime(timezone=True), default=sa.func.now()),
        sa.Column("decision", sa.Boolean),
        sa.Column("decision_timestamp", sa.DateTime(timezone=True)),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table("link_history")
