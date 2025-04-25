import os

from flask import Flask


# Adapted from https://flask.palletsprojects.com/en/stable/tutorial/
def create_app(test_config=None, **kwargs):
    app = Flask(__name__, instance_relative_config=True, **kwargs)
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

    from pir_pipeline.dashboard import index, review, search

    app.register_blueprint(index.bp)
    app.add_url_rule("/", endpoint="index")

    app.register_blueprint(search.bp)
    app.register_blueprint(review.bp)

    return app
