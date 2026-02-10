-- Universal Agent Framework - Database Initialization Script
--
-- This script is executed when the PostgreSQL container is first created.
-- It sets up the database with necessary extensions and configuration.

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- UUID generation functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- Trigram matching for full-text search

-- Configure database settings
ALTER DATABASE universal_agent SET timezone TO 'UTC';
ALTER DATABASE universal_agent SET client_encoding TO 'UTF8';
ALTER DATABASE universal_agent SET search_path TO public;

-- Add comments for documentation
COMMENT ON DATABASE universal_agent IS 'Universal Agent Framework Database';
COMMENT ON EXTENSION "uuid-ossp" IS 'Generate UUIDs for primary keys';
COMMENT ON EXTENSION "pg_trgm" IS 'Trigram matching for text search similarity';
