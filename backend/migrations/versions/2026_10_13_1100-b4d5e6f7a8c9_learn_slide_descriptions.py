"""learn slide descriptions

Revision ID: b4d5e6f7a8c9
Revises: a3c4d5e6f7b8
Create Date: 2026-10-13 11:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b4d5e6f7a8c9'
down_revision: Union[str, Sequence[str], None] = 'a3c4d5e6f7b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    for column in ('description', 'description_ru', 'description_en'):
        op.add_column('exercise_options', sa.Column(column, sa.String(255), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    for column in ('description_en', 'description_ru', 'description'):
        op.drop_column('exercise_options', column)
