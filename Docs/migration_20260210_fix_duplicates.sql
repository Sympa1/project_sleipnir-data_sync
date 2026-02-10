-- Duplikate in SyncFiles finden und bereinigen
-- Datum: 2026-02-10

-- 1. Zeige alle Duplikate (file_path kommt mehrfach vor)
SELECT file_path, COUNT(*) as count
FROM SyncFiles
GROUP BY file_path
HAVING COUNT(*) > 1;

-- 2. Zeige Details der Duplikate
SELECT sync_file_id, file_path, hash_value, created_at, last_modified
FROM SyncFiles
WHERE file_path IN (
    SELECT file_path
    FROM SyncFiles
    GROUP BY file_path
    HAVING COUNT(*) > 1
)
ORDER BY file_path, created_at;

-- 3. Bereinigung: Behalte nur den neuesten Eintrag pro file_path
-- WARNUNG: Erstelle VORHER ein Backup!
-- Löscht alle Duplikate außer dem mit der höchsten sync_file_id (= neuester)
DELETE FROM SyncFiles
WHERE sync_file_id NOT IN (
    SELECT MAX(sync_file_id)
    FROM (SELECT * FROM SyncFiles) AS temp
    GROUP BY file_path
);

-- 4. Prüfe ob UNIQUE Constraint existiert
SHOW CREATE TABLE SyncFiles;

-- 5. Falls UNIQUE Constraint fehlt, hinzufügen:
-- ALTER TABLE SyncFiles ADD UNIQUE KEY unique_file_path (file_path);

-- 6. Prüfung: Sollte 0 Duplikate zeigen
SELECT file_path, COUNT(*) as count
FROM SyncFiles
GROUP BY file_path
HAVING COUNT(*) > 1;
