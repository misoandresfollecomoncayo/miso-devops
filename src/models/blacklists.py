from database import db

class Blacklists(db.Model):
    __tablename__ = "blacklists"

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(254), nullable=False)
    app_uuid = db.Column(db.UUID, nullable=False)
    blocked_reason = db.Column(db.String(255), nullable=True)
    ip_address = db.Column(db.String(45), nullable=False)
    created_timestamp = db.Column(db.DateTime, nullable=False)