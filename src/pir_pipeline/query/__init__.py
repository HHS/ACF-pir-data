"""PIR QA Dashboard"""

import hashlib
import os

from flask import Flask
from flask.sessions import SecureCookieSessionInterface
from itsdangerous import URLSafeTimedSerializer

from pir_pipeline.query import core, db


# Adapted from GPT 4.0
class CustomSessionInterface(SecureCookieSessionInterface):
    """Change how session is serialized"""

    def get_signing_serializer(self, app):
        return URLSafeTimedSerializer(
            app.secret_key,
            salt="cookie-session",
            serializer=None,
            signer_kwargs={"digest_method": hashlib.sha256},
        )


# Adapted from https://flask.palletsprojects.com/en/stable/tutorial/
def create_app(test_config: dict = None, **kwargs) -> Flask:
    """Create the Flask application

    Args:
        test_config (dict, optional): Test configuration. Defaults to None.

    Returns:
        Flask: A Flask application
    """
    app = Flask(__name__, instance_relative_config=True, **kwargs)
    app.session_interface = CustomSessionInterface()

    if test_config is None:
        app.config.from_pyfile("config.py", silent=True)
    else:
        app.config.from_mapping(test_config)

    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    db.init_app(app)

    app.register_blueprint(core.bp)

    return app
