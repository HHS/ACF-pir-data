from functools import wraps
from getpass import getuser

from flask import flash, redirect, url_for


# https://flask.palletsprojects.com/en/stable/tutorial/views/
def administrator(view):
    @wraps(view)
    def wrapped_view(**kwargs):
        if getuser() not in [
            "jesse.escobar",
            "emily.kowall",
            "reggie.gilliard",
            "alecsandra.velez",
        ]:
            flash("You are not authorized to access this page.")
            return redirect(url_for("index"))

        return view(**kwargs)

    return wrapped_view
