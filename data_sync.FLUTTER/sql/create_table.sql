CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY,
        key TEXT UNIQUE NOT NULL,
        value TEXT
      );

