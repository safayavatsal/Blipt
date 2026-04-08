"""
Database schema for production backend (PostgreSQL via SQLAlchemy/Supabase).
Currently a blueprint — in-memory stores are used until migration.
"""

# SQL schema for reference:

SCHEMA = """
-- Users (Sign in with Apple)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_user_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_premium BOOLEAN DEFAULT FALSE,
    subscription_expires_at TIMESTAMPTZ,
    referral_code TEXT UNIQUE,
    bonus_lookups INTEGER DEFAULT 0
);

-- Vehicle lookup cache (24h TTL)
CREATE TABLE vehicle_cache (
    plate TEXT PRIMARY KEY,
    data JSONB NOT NULL,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);

-- Lookup history (synced across devices)
CREATE TABLE lookups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    plate TEXT NOT NULL,
    country TEXT NOT NULL,
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_id TEXT NOT NULL,
    status TEXT NOT NULL,  -- active, expired, cancelled
    started_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    transaction_id TEXT
);

-- Community submissions
CREATE TABLE submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    country TEXT NOT NULL,
    submission_type TEXT NOT NULL,
    region_code TEXT,
    rto_code TEXT,
    suggested_name TEXT,
    suggested_district TEXT,
    notes TEXT,
    status TEXT DEFAULT 'pending_review',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ
);

-- User feedback (accuracy tracking)
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    plate_format TEXT NOT NULL,  -- standard, bhSeries, moroccan, uae, etc.
    country TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    confidence REAL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- A/B test assignments
CREATE TABLE ab_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    test_name TEXT NOT NULL,
    variant TEXT NOT NULL,  -- 'control', 'variant_a', 'variant_b'
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, test_name)
);

-- Indexes
CREATE INDEX idx_lookups_user ON lookups(user_id);
CREATE INDEX idx_lookups_plate ON lookups(plate);
CREATE INDEX idx_vehicle_cache_expires ON vehicle_cache(expires_at);
CREATE INDEX idx_feedback_country ON feedback(country, plate_format);
CREATE INDEX idx_ab_tests_user ON ab_tests(user_id, test_name);
"""
