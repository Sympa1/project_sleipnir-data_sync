from .sqlite_handler import SqliteHandler
from .api_client import ApiClient

class ManifestHandler:
    def __init__(self):
        self.db_handler = SqliteHandler()
        self.api = ApiClient("Test")