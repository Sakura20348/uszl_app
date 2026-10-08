"""sign transcription in Russian and English

Revision ID: e1a2b3c4d5f6
Revises: d8f5494e3320
Create Date: 2026-10-07 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e1a2b3c4d5f6'
down_revision: Union[str, Sequence[str], None] = 'd8f5494e3320'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('signs', sa.Column('transcription_ru', sa.String(length=255), nullable=True))
    op.add_column('signs', sa.Column('transcription_en', sa.String(length=255), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('signs', 'transcription_en')
    op.drop_column('signs', 'transcription_ru')
