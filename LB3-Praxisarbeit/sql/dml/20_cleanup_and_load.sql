-- ============================================================
-- M141 LB3 – Backpacker_LB3 – Giovanni Merola
-- 20_cleanup_and_load.sql
-- Konsolidiert Staging-Daten und füllt die Zieltabellen
-- (NULL-Sentinel entfernen, FK-Mapping, Type-Cast)
-- Autor: Giovanni Merola · 30.06.2026
-- ============================================================

USE backpacker_lb3_giovanni;

-- Strikten Modus für diesen Cleanup-Lauf entschärfen:
-- übergrosse Werte werden lieber abgeschnitten als die ganze
-- Transaktion zu killen. Die Cleanup-Logik nutzt zusätzlich LEFT()
-- als defensive Sicherung.
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';

-- FKs temporär aus, damit Reihenfolge unkritisch ist
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE tbl_positionen;
TRUNCATE TABLE tbl_buchung;
TRUNCATE TABLE tbl_benutzer;
TRUNCATE TABLE tbl_personen;
TRUNCATE TABLE tbl_land;
TRUNCATE TABLE tbl_leistung;
SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------------------------------------------
-- tbl_land  (INSERT IGNORE: Quelldaten enthalten 2 Duplikate
--            'Schweiz' und 'Liechtenstein' -> werden übersprungen)
-- ----------------------------------------------------------------
INSERT IGNORE INTO tbl_land (Land_ID, Land)
SELECT NULLIF(TRIM(Land_ID), '')   AS Land_ID,
       TRIM(Land)                  AS Land
FROM   stg_land
WHERE  TRIM(IFNULL(Land,'')) <> ''
  AND  UPPER(TRIM(IFNULL(Land,''))) <> 'NULL';

-- ----------------------------------------------------------------
-- tbl_leistung  (INSERT IGNORE: defensiv gegen evtl. Duplikate)
-- ----------------------------------------------------------------
INSERT IGNORE INTO tbl_leistung (LeistungID, Beschreibung)
SELECT NULLIF(TRIM(LeistungID),''),
       TRIM(Beschreibung)
FROM   stg_leistung
WHERE  TRIM(IFNULL(Beschreibung,'')) <> ''
  AND  UPPER(TRIM(IFNULL(Beschreibung,''))) <> 'NULL';

-- ----------------------------------------------------------------
-- tbl_personen  – NULL-Sentinel "NULL"-String in echtes NULL
-- ----------------------------------------------------------------
INSERT INTO tbl_personen
    (Personen_ID, Titel, Vorname, Name, Strasse, PLZ, Ort,
     Anrede, Telefon, erfasst, Sprache)
SELECT
    NULLIF(TRIM(Personen_ID),'')                              AS Personen_ID,
    NULLIF(NULLIF(TRIM(Titel),''),  'NULL')                   AS Titel,
    NULLIF(NULLIF(TRIM(Vorname),''),'NULL')                   AS Vorname,
    COALESCE(NULLIF(NULLIF(TRIM(Name),''),'NULL'), '???')     AS Name,   -- Pflichtfeld
    NULLIF(NULLIF(TRIM(Strasse),''),'NULL')                   AS Strasse,
    NULLIF(NULLIF(TRIM(PLZ),''),    'NULL')                   AS PLZ,
    NULLIF(NULLIF(TRIM(Ort),''),    'NULL')                   AS Ort,
    NULLIF(NULLIF(TRIM(Anrede),''), 'NULL')                   AS Anrede,
    NULLIF(NULLIF(TRIM(Telefon),''),'NULL')                   AS Telefon,
    NULLIF(NULLIF(TRIM(erfasst),''),'NULL')                   AS erfasst,
    LEFT(NULLIF(NULLIF(TRIM(Sprache),''),'NULL'),2)           AS Sprache
FROM stg_personen
WHERE TRIM(IFNULL(Personen_ID,'')) <> '';

-- ----------------------------------------------------------------
-- tbl_benutzer  (INSERT IGNORE: Quelldaten enthalten Duplikate
--                in `Benutzername`, z. B. 'mueller' zweimal)
-- ----------------------------------------------------------------
INSERT IGNORE INTO tbl_benutzer
    (Benutzer_ID, Benutzername, Password, Vorname, Name,
     Benutzergruppe, erfasst, deaktiviert, aktiv)
SELECT
    NULLIF(TRIM(Benutzer_ID),'')                              AS Benutzer_ID,
    TRIM(Benutzername)                                        AS Benutzername,
    NULLIF(NULLIF(TRIM(Password),''),'NULL')                  AS Password,
    NULLIF(NULLIF(TRIM(Vorname),''), 'NULL')                  AS Vorname,
    NULLIF(NULLIF(TRIM(Name),''),    'NULL')                  AS Name,
    CAST(IFNULL(NULLIF(TRIM(Benutzergruppe),''),'1') AS UNSIGNED) AS Benutzergruppe,
    IFNULL(NULLIF(NULLIF(TRIM(erfasst),''),'NULL'), CURRENT_TIMESTAMP) AS erfasst,
    -- Sentinel '1000-01-01' → NULL
    CASE WHEN TRIM(deaktiviert) IN ('','NULL','1000-01-01') THEN NULL
         ELSE TRIM(deaktiviert) END                           AS deaktiviert,
    CAST(IFNULL(NULLIF(TRIM(aktiv),''),'1') AS UNSIGNED)      AS aktiv
FROM stg_benutzer
WHERE TRIM(IFNULL(Benutzer_ID,'')) <> ''
  AND TRIM(IFNULL(Benutzername,'')) <> '';

-- ----------------------------------------------------------------
-- tbl_buchung
--   - Land_FS = 0 → NULL  (Sentinel)
--   - Verwaiste Personen_FS / Land_FS auf NULL setzen
--   - Inkonsistente Daten (Abreise < Ankunft) → Abreise = NULL,
--     damit chk_buchung_zeitraum nicht greift. Vorgang dokumentiert
--     in Testprotokoll.
-- ----------------------------------------------------------------
INSERT INTO tbl_buchung (Buchungs_ID, Personen_FS, Ankunft, Abreise, Land_FS)
SELECT
    NULLIF(TRIM(s.Buchungs_ID),''),
    CASE WHEN p.Personen_ID IS NULL THEN NULL ELSE p.Personen_ID END,
    NULLIF(NULLIF(TRIM(s.Ankunft),''),'NULL')                              AS Ankunft_clean,
    CASE
        WHEN NULLIF(NULLIF(TRIM(s.Abreise),''),'NULL') IS NULL THEN NULL
        WHEN NULLIF(NULLIF(TRIM(s.Ankunft),''),'NULL') IS NULL THEN
             NULLIF(NULLIF(TRIM(s.Abreise),''),'NULL')
        WHEN NULLIF(NULLIF(TRIM(s.Abreise),''),'NULL') <
             NULLIF(NULLIF(TRIM(s.Ankunft),''),'NULL') THEN NULL
        ELSE NULLIF(NULLIF(TRIM(s.Abreise),''),'NULL')
    END                                                                    AS Abreise_clean,
    CASE WHEN l.Land_ID IS NULL THEN NULL ELSE l.Land_ID END
FROM stg_buchung s
LEFT JOIN tbl_personen p
       ON p.Personen_ID = CAST(NULLIF(TRIM(s.Personen_FS),'') AS UNSIGNED)
LEFT JOIN tbl_land l
       ON l.Land_ID = CAST(NULLIF(TRIM(s.Land_FS),'') AS UNSIGNED)
       AND TRIM(s.Land_FS) NOT IN ('0','')         -- 0 = Sentinel
WHERE TRIM(IFNULL(s.Buchungs_ID,'')) <> '';

-- ----------------------------------------------------------------
-- tbl_positionen
--   - verwaiste Benutzer_FS auf NULL
--   - verwaiste Leistung_FS auf NULL (Freitext bleibt)
-- ----------------------------------------------------------------
INSERT INTO tbl_positionen
    (Positions_ID, Buchungs_FS, Konto, Anzahl, Preis, Rabatt,
     Benutzer_FS, erfasst, Leistung_Text, Leistung_FS)
SELECT
    NULLIF(TRIM(s.Positions_ID),''),
    CASE WHEN b.Buchungs_ID IS NULL THEN NULL ELSE b.Buchungs_ID END,
    CAST(IFNULL(NULLIF(TRIM(s.Konto),''),'0') AS SIGNED),
    CAST(IFNULL(NULLIF(TRIM(s.Anzahl),''),'0') AS SIGNED),
    CAST(IFNULL(NULLIF(TRIM(s.Preis),''),'0') AS DECIMAL(10,2)),
    -- Rabatt: 0..100 erzwingen (CHECK chk_pos_rabatt). Werte ausserhalb
    -- werden auf den nächstgelegenen gültigen Wert geklammert.
    LEAST(100, GREATEST(0, CAST(IFNULL(NULLIF(TRIM(s.Rabatt),''),'0') AS DECIMAL(5,2)))),
    CASE WHEN u.Benutzer_ID IS NULL THEN NULL ELSE u.Benutzer_ID END,
    IFNULL(NULLIF(NULLIF(TRIM(s.erfasst),''),'NULL'),'2000-01-01 00:00:00'),
    NULLIF(NULLIF(TRIM(s.Leistung_Text),''),'NULL'),
    CASE WHEN le.LeistungID IS NULL THEN NULL ELSE le.LeistungID END
FROM stg_positionen s
LEFT JOIN tbl_buchung   b  ON b.Buchungs_ID = CAST(NULLIF(TRIM(s.Buchungs_FS),'') AS UNSIGNED)
LEFT JOIN tbl_benutzer  u  ON u.Benutzer_ID = CAST(NULLIF(TRIM(s.Benutzer_FS),'') AS UNSIGNED)
LEFT JOIN tbl_leistung  le ON le.LeistungID = CAST(NULLIF(TRIM(s.Leistung_FS),'') AS UNSIGNED)
WHERE TRIM(IFNULL(s.Positions_ID,'')) <> '';

-- ----------------------------------------------------------------
-- Importkontrolle (Soll/Ist)
-- ----------------------------------------------------------------
SELECT 'tbl_land'       AS tbl, (SELECT COUNT(*) FROM stg_land)       AS stg,
                                (SELECT COUNT(*) FROM tbl_land)       AS prod
UNION ALL SELECT 'tbl_leistung',   (SELECT COUNT(*) FROM stg_leistung),   (SELECT COUNT(*) FROM tbl_leistung)
UNION ALL SELECT 'tbl_personen',   (SELECT COUNT(*) FROM stg_personen),   (SELECT COUNT(*) FROM tbl_personen)
UNION ALL SELECT 'tbl_benutzer',   (SELECT COUNT(*) FROM stg_benutzer),   (SELECT COUNT(*) FROM tbl_benutzer)
UNION ALL SELECT 'tbl_buchung',    (SELECT COUNT(*) FROM stg_buchung),    (SELECT COUNT(*) FROM tbl_buchung)
UNION ALL SELECT 'tbl_positionen', (SELECT COUNT(*) FROM stg_positionen), (SELECT COUNT(*) FROM tbl_positionen);
