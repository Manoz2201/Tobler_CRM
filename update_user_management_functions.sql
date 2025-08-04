-- Alternative: Update functions to use correct tables instead of removing them
-- This script updates the functions to work with users and dev_user tables directly

-- Update sync_user_management_data function to work with users/dev_user directly
CREATE OR REPLACE FUNCTION sync_user_management_data()
RETURNS TRIGGER AS $$
BEGIN
    -- This function is no longer needed since we're not using user_management table
    -- Just return the NEW or OLD record
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Update sync_dev_user_to_user_management function
CREATE OR REPLACE FUNCTION sync_dev_user_to_user_management()
RETURNS TRIGGER AS $$
BEGIN
    -- This function is no longer needed since we're not using user_management table
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update get_user_management_data to get from users and dev_user
CREATE OR REPLACE FUNCTION get_user_management_data()
RETURNS TABLE (
    id uuid,
    user_id uuid,
    username text,
    employee_code text,
    email text,
    user_type text,
    device_type text,
    is_user_online boolean,
    session_active boolean,
    verified boolean,
    created_at timestamptz,
    updated_at timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.id as user_id,
        u.username,
        u.employee_code,
        u.email,
        u.user_type,
        u.device_type,
        u.is_user_online,
        u.session_active,
        u.verified,
        u.created_at,
        u.updated_at
    FROM users u
    UNION ALL
    SELECT 
        d.id,
        d.user_id,
        d.username,
        d.employee_code,
        d.email,
        d.user_type,
        d.device_type,
        false as is_user_online,
        d.session_active,
        d.verified,
        d.created_at,
        d.updated_at
    FROM dev_user d
    ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Update get_detailed_user_management_data
CREATE OR REPLACE FUNCTION get_detailed_user_management_data()
RETURNS TABLE (
    id uuid,
    user_id uuid,
    username text,
    employee_code text,
    email text,
    user_type text,
    device_type text,
    machine_id text,
    is_user_online boolean,
    session_active boolean,
    verified boolean,
    session_id text,
    created_at timestamptz,
    updated_at timestamptz,
    last_activity timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.id as user_id,
        u.username,
        u.employee_code,
        u.email,
        u.user_type,
        u.device_type,
        u.machine_id,
        u.is_user_online,
        u.session_active,
        u.verified,
        u.session_id,
        u.created_at,
        u.updated_at,
        u.updated_at as last_activity
    FROM users u
    UNION ALL
    SELECT 
        d.id,
        d.user_id,
        d.username,
        d.employee_code,
        d.email,
        d.user_type,
        d.device_type,
        d.machine_id,
        false as is_user_online,
        d.session_active,
        d.verified,
        d.session_id,
        d.created_at,
        d.updated_at,
        d.updated_at as last_activity
    FROM dev_user d
    ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Update search_user_management_data
CREATE OR REPLACE FUNCTION search_user_management_data(search_term text)
RETURNS TABLE (
    id uuid,
    user_id uuid,
    username text,
    employee_code text,
    email text,
    user_type text,
    device_type text,
    is_user_online boolean,
    session_active boolean,
    verified boolean,
    created_at timestamptz,
    updated_at timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.id as user_id,
        u.username,
        u.employee_code,
        u.email,
        u.user_type,
        u.device_type,
        u.is_user_online,
        u.session_active,
        u.verified,
        u.created_at,
        u.updated_at
    FROM users u
    WHERE 
        u.username ILIKE '%' || search_term || '%' OR
        u.email ILIKE '%' || search_term || '%' OR
        u.user_type ILIKE '%' || search_term || '%' OR
        u.employee_code ILIKE '%' || search_term || '%'
    UNION ALL
    SELECT 
        d.id,
        d.user_id,
        d.username,
        d.employee_code,
        d.email,
        d.user_type,
        d.device_type,
        false as is_user_online,
        d.session_active,
        d.verified,
        d.created_at,
        d.updated_at
    FROM dev_user d
    WHERE 
        d.username ILIKE '%' || search_term || '%' OR
        d.email ILIKE '%' || search_term || '%' OR
        d.user_type ILIKE '%' || search_term || '%' OR
        d.employee_code ILIKE '%' || search_term || '%'
    ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Update get_user_management_stats
CREATE OR REPLACE FUNCTION get_user_management_stats()
RETURNS TABLE (
    total_users bigint,
    online_users bigint,
    verified_users bigint,
    active_sessions bigint,
    users_by_type json
) AS $$
DECLARE
    type_stats json;
BEGIN
    -- Get user type statistics from both tables
    SELECT json_object_agg(user_type, count) INTO type_stats
    FROM (
        SELECT user_type, COUNT(*) as count
        FROM (
            SELECT user_type FROM users
            UNION ALL
            SELECT user_type FROM dev_user
        ) combined_users
        GROUP BY user_type
    ) t;
    
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM users) + (SELECT COUNT(*) FROM dev_user) as total_users,
        (SELECT COUNT(*) FROM users WHERE is_user_online = true) as online_users,
        (SELECT COUNT(*) FROM users WHERE verified = true) + (SELECT COUNT(*) FROM dev_user WHERE verified = true) as verified_users,
        (SELECT COUNT(*) FROM users WHERE session_active = true) + (SELECT COUNT(*) FROM dev_user WHERE session_active = true) as active_sessions,
        COALESCE(type_stats, '{}'::json) as users_by_type;
END;
$$ LANGUAGE plpgsql; 