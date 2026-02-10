-- Migration: Konvertiere alle Hash-Werte zu lowercase
-- Datum: 2026-02-10
-- Grund: Python-Client verwendet lowercase, C#-Server verwendete uppercase

-- SyncFiles Tabelle: Hash-Werte zu lowercase
UPDATE SyncFiles 
SET hash_value = LOWER(hash_value)
WHERE hash_value IS NOT NULL;

-- LastSyncState Tabelle: Hash-Werte zu lowercase
UPDATE LastSyncState 
SET hash_value = LOWER(hash_value)
WHERE hash_value IS NOT NULL;

-- Prüfung: Zeige alle Hashes an (sollten jetzt lowercase sein)
SELECT 'SyncFiles' as table_name, file_path, hash_value FROM SyncFiles LIMIT 5
UNION ALL
SELECT 'LastSyncState' as table_name, file_path, hash_value FROM LastSyncState LIMIT 5;
