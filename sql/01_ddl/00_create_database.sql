-- =============================================================================
-- 00_create_database.sql
-- Purpose: Create the medallion warehouse database and set session context.
-- Run this script first before any other DDL or ETL scripts.
-- =============================================================================

DROP DATABASE IF EXISTS medallion_dw;
CREATE DATABASE medallion_dw
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE medallion_dw;
