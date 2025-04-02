import os

from flask import Flask


# Adapted from https://flask.palletsprojects.com/en/stable/tutorial/
def create_app(test_config=None):
    app = Flask(__name__, instance_relative_config=True)
    app.config.from_mapping(SECRET_KEY="dev")

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

    from pir_pipeline.dashboard import qa

    app.register_blueprint(qa.bp)
    app.add_url_rule("/", endpoint="index")

    return app
