"""PIR QA Dashboard"""

import hashlib
import os

from flask import Flask
from flask.sessions import SecureCookieSessionInterface
from itsdangerous import URLSafeTimedSerializer


# Adapted from GPT 4.0
class CustomSessionInterface(SecureCookieSessionInterface):
    """Change how session is hashed"""

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
    app.secret_key = "dev"
    app.session_interface = CustomSessionInterface()

    if test_config is None:
        app.config.from_pyfile("config.py", silent=True)
    else:
        app.config.from_mapping(test_config)

    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    from pir_pipeline.dashboard import db

    db.init_app(app)

    from pir_pipeline.dashboard import index, review, search

    app.register_blueprint(index.bp)
    app.add_url_rule("/", endpoint="index")

    app.register_blueprint(search.bp)
    app.register_blueprint(review.bp)

    return app
