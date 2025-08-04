-- Remove all triggers that reference user_management functions
DROP TRIGGER IF EXISTS trg_sync_dev_user_update ON dev_user;
DROP TRIGGER IF EXISTS sync_users_to_user_management ON users;
DROP TRIGGER IF EXISTS sync_dev_users_to_user_management ON dev_user;

-- Remove all functions that reference user_management table
DROP FUNCTION IF EXISTS sync_user_management_data();
DROP FUNCTION IF EXISTS sync_dev_user_to_user_management();
DROP FUNCTION IF EXISTS sync_all_user_management_data();
DROP FUNCTION IF EXISTS get_user_management_data();
DROP FUNCTION IF EXISTS get_detailed_user_management_data();
DROP FUNCTION IF EXISTS search_user_management_data();
DROP FUNCTION IF EXISTS get_user_management_stats();

-- Optional: Drop the user_management table if it exists
-- DROP TABLE IF EXISTS user_management; 