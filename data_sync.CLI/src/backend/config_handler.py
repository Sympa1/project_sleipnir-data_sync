import json
import os

class ConfigHandler:
    def __init__(self, config_path='config.json'):
        self.config_path = config_path
        self.config = self.load_config()

    def load_config(self):
        if not os.path.exists(self.config_path):
            return {}
        with open(self.config_path, 'r') as file:
            return json.load(file)

    def save_config(self):
        with open(self.config_path, 'w') as file:
            json.dump(self.config, file, indent=4)

    def get(self, key, default=None):
        return self.config.get(key, default)

    def set(self, key, value):
        self.config[key] = value
        self.save_config()