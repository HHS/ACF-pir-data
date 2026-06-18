"""Module for retrieving and managing data from the HSES API."""

import os
import shutil
from datetime import date
from io import BytesIO
from tempfile import mkdtemp
from typing import Optional, Self
from zipfile import ZipFile

import boto3  # type: ignore
import requests

from pir_pipeline.hses.urls import PROD_URL, STAGING_URL, TEST_URL


class HSES:
    """Class for interfacing with the HSES API."""

    def __init__(self, url: str = PROD_URL):
        """
        Initialize the HSES object with API credentials and URL.

        Args:
            url (str, optional): The URL to send requests to. Defaults to PROD_URL.
        """
        api_keys = {
            STAGING_URL: os.environ.get("HSES_API_KEY_STAGING", ""),
            TEST_URL: os.environ.get("HSES_API_KEY_TEST", ""),
            PROD_URL: os.environ.get("HSES_API_KEY_PROD", ""),
        }
        self.__user: str = os.environ["HSES_API_USER"]
        self.__key: str = api_keys[url]
        self.__auth: tuple[str, str] = (self.__user, self.__key)
        self.__url: str = url
        self.__content: BytesIO
        self.__tempdir: str

    @property
    def content(self):
        """Return the content retrieved from the API."""
        return self.__content

    @property
    def tempdir(self):
        """Return the temporary directory used to store unzipped files."""
        return self.__tempdir

    def get_data(self) -> Self:
        """
        Retrieve data from the HSES API and store it in memory.

        Returns:
            Self: The instance of the class.
        """
        response = requests.get(self.__url, auth=self.__auth)
        response.raise_for_status()

        self.__content = BytesIO(response.content)

        return self

    def unzip(self) -> Self:
        """
        Unzip the retrieved data into a temporary directory and append a datestamp to each file.

        Returns:
            Self: The instance of the class.
        """
        self.__tempdir = mkdtemp()

        zip_file = ZipFile(self.__content)
        zip_file.extractall(self.__tempdir)

        files = os.listdir(self.__tempdir)

        datestamp = date.today().strftime("%Y_%m_%d")
        for file in files:
            base, extension = os.path.splitext(file)
            new_name = f"{base}_{datestamp}{extension}"
            os.rename(
                os.path.join(self.__tempdir, file),
                os.path.join(self.__tempdir, new_name),
            )

        return self

    def export(
        self,
        path: Optional[str] = None,
        Bucket: Optional[str] = None,
        Key: Optional[str] = None,
    ) -> Self:
        """
        Export the unzipped files to a specified local directory or to an S3 bucket.

        Args:
            path (str, optional): Local directory to export files to.
            Bucket (str, optional): S3 bucket name.
            Key (str, optional): S3 object key.

        Raises:
            ValueError: If neither `path` nor both `Bucket` and `Key` are specified.
            ValueError: If only one of `Bucket` or `Key` is specified, or if both local and S3 options are provided.

        Returns:
            Self: The instance of the class.
        """
        path_bool = bool(path)
        bucket_bool = bool(Bucket)
        key_bool = bool(Key)
        if not (path_bool ^ (bucket_bool and key_bool)):  # xor operator
            raise ValueError("Must specify `path` or (`Bucket` and `Key`)")
        elif not ((path_bool ^ bucket_bool) and (path_bool ^ key_bool)):
            raise ValueError("Must specify `path` or (`Bucket` and `Key`)")

        files = os.scandir(self.__tempdir)
        if path:
            for file in files:
                shutil.copy(file.path, path)
        elif Bucket:
            s3 = boto3.client("s3")
            for file in files:
                with open(file, "rb") as f:
                    s3.put_object(
                        Body=f.read(),
                        Bucket=Bucket,
                        Key=f"{Key}/{file.name}",
                    )

        return self

    def clean_up_tempdir(self) -> Self:
        """
        Remove the temporary directory used for unzipping files.

        Returns:
            Self: The instance of the class.
        """
        shutil.rmtree(self.__tempdir)
        return self

    def __del__(self):
        """Destructor: clean up the temporary directory if it exists."""
        self.clean_up_tempdir()
