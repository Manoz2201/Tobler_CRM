# 🔧 Supabase Troubleshooting & Recovery Guide

## 📋 Overview
This guide helps diagnose and resolve Supabase issues, including table blockages and restoration methods.

---

## 🔍 **DIAGNOSTIC STEPS**

### **1. Check Supabase Dashboard Status**
```bash
# Visit Supabase Dashboard
https://supabase.com/dashboard/project/vlapmwwroraolpgyfrtg

# Check these areas:
✅ Database Status
✅ API Status  
✅ Auth Status
✅ Storage Status
✅ Edge Functions Status
```

### **2. Test API Connectivity**
```bash
# Test your Supabase URL
curl -I https://vlapmwwroraolpgyfrtg.supabase.co

# Test with your API key
curl -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ" \
  https://vlapmwwroraolpgyfrtg.supabase.co/rest/v1/
```

### **3. Check Database Tables for Blockages**
```sql
-- Check for active locks
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    query
FROM pg_stat_activity 
WHERE state != 'idle' 
AND query NOT ILIKE '%pg_stat_activity%';

-- Check for blocked queries
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON (blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid)
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Check table sizes and potential issues
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE schemaname = 'public'
ORDER BY tablename, attname;
```

---

## 🚨 **COMMON ISSUES & SOLUTIONS**

### **1. Table Lock Issues**
```sql
-- Kill blocking processes (use with caution)
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' 
AND query NOT ILIKE '%pg_stat_activity%'
AND pid != pg_backend_pid();

-- Unlock specific tables
SELECT pg_advisory_unlock_all();

-- Check for long-running transactions
SELECT 
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

### **2. RLS (Row Level Security) Issues**
```sql
-- Check RLS status on tables
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public';

-- Disable RLS temporarily for testing
ALTER TABLE leads DISABLE ROW LEVEL SECURITY;
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Re-enable after testing
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

### **3. Connection Pool Issues**
```sql
-- Check connection count
SELECT count(*) FROM pg_stat_activity;

-- Check max connections
SHOW max_connections;

-- Reset connection pool
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = current_database()
AND pid <> pg_backend_pid();
```

---

## 🔄 **RESTORATION METHODS**

### **1. Reset Supabase Project Settings**

#### **Via Supabase Dashboard:**
1. **Go to Project Settings**
   - Navigate to: https://supabase.com/dashboard/project/vlapmwwroraolpgyfrtg/settings
   
2. **Reset Database**
   - Go to Database → Reset
   - This will reset all data but keep schema
   
3. **Reset Auth Settings**
   - Go to Authentication → Settings
   - Reset to default configurations

#### **Via SQL Commands:**
```sql
-- Reset all tables to initial state
TRUNCATE TABLE leads, users, lead_contacts, lead_attachments, 
           lead_activity, queries, proposal_input, proposal_file, 
           proposal_remark, admin_response, invitation, system_config 
RESTART IDENTITY CASCADE;

-- Reset sequences
ALTER SEQUENCE leads_id_seq RESTART WITH 1;
ALTER SEQUENCE users_id_seq RESTART WITH 1;
-- Repeat for all tables with sequences
```

### **2. Restore from Backup**
```bash
# If you have a backup file
psql -h vlapmwwroraolpgyfrtg.supabase.co -U postgres -d postgres -f backup_file.sql

# Restore specific tables
psql -h vlapmwwroraolpgyfrtg.supabase.co -U postgres -d postgres -c "DROP TABLE IF EXISTS leads CASCADE;"
psql -h vlapmwwroraolpgyfrtg.supabase.co -U postgres -d postgres -f leads_backup.sql
```

### **3. Recreate Tables**
```sql
-- Drop and recreate all tables
DROP TABLE IF EXISTS 
    leads, users, dev_user, lead_contacts, lead_attachments,
    lead_activity, queries, proposal_input, proposal_file,
    proposal_remark, admin_response, invitation, system_config CASCADE;

-- Then run the table creation scripts from SUPABASE_CONFIGURATION.md
```

---

## 🛠️ **FLUTTER APP DIAGNOSTICS**

### **1. Test Supabase Connection in Flutter**
```dart
// Add this test function to your app
Future<void> testSupabaseConnection() async {
  try {
    final client = Supabase.instance.client;
    
    // Test basic connection
    final response = await client
        .from('users')
        .select('count')
        .limit(1);
    
    print('✅ Supabase connection successful');
    print('Response: $response');
    
  } catch (e) {
    print('❌ Supabase connection failed: $e');
    
    // Check specific error types
    if (e.toString().contains('timeout')) {
      print('🔍 Issue: Connection timeout');
    } else if (e.toString().contains('unauthorized')) {
      print('🔍 Issue: Authentication problem');
    } else if (e.toString().contains('not found')) {
      print('🔍 Issue: Table or column not found');
    }
  }
}
```

### **2. Check Environment Variables**
```dart
// Verify your Supabase configuration
void checkSupabaseConfig() {
  final url = 'https://vlapmwwroraolpgyfrtg.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ';
  
  print('URL: $url');
  print('Anon Key: ${anonKey.substring(0, 20)}...');
  
  // Test URL accessibility
  http.get(Uri.parse(url)).then((response) {
    print('URL Status: ${response.statusCode}');
  });
}
```

---

## 🔧 **AUTOMATED RECOVERY SCRIPT**

### **Create Recovery Script**
```bash
#!/bin/bash
# supabase_recovery.sh

echo "🔧 Starting Supabase Recovery Process..."

# 1. Test connectivity
echo "📡 Testing Supabase connectivity..."
curl -I https://vlapmwwroraolpgyfrtg.supabase.co

# 2. Check database status
echo "🗄️ Checking database status..."
psql "postgresql://postgres:[YOUR_PASSWORD]@vlapmwwroraolpgyfrtg.supabase.co:5432/postgres" -c "
SELECT 
    pid,
    usename,
    application_name,
    state,
    query_start
FROM pg_stat_activity 
WHERE state != 'idle';"

# 3. Kill long-running processes
echo "🔄 Killing long-running processes..."
psql "postgresql://postgres:[YOUR_PASSWORD]@vlapmwwroraolpgyfrtg.supabase.co:5432/postgres" -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' 
AND (now() - query_start) > interval '10 minutes';"

echo "✅ Recovery process completed!"
```

---

## 📊 **MONITORING & PREVENTION**

### **1. Set Up Monitoring**
```sql
-- Create monitoring table
CREATE TABLE IF NOT EXISTS system_monitor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    check_type TEXT NOT NULL,
    status TEXT NOT NULL,
    details JSONB,
    response_time_ms INTEGER
);

-- Monitor table sizes
CREATE OR REPLACE FUNCTION monitor_table_sizes()
RETURNS TABLE (
    table_name TEXT,
    table_size TEXT,
    index_size TEXT,
    total_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        schemaname||'.'||tablename as table_name,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size,
        pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as index_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size
    FROM pg_tables 
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
END;
$$ LANGUAGE plpgsql;
```

### **2. Automated Health Checks**
```dart
// Add to your Flutter app
class SupabaseHealthChecker {
  static Future<bool> performHealthCheck() async {
    try {
      final client = Supabase.instance.client;
      
      // Test basic operations
      await client.from('users').select('count').limit(1);
      await client.from('leads').select('count').limit(1);
      
      print('✅ Supabase health check passed');
      return true;
      
    } catch (e) {
      print('❌ Supabase health check failed: $e');
      return false;
    }
  }
  
  static Future<void> scheduleHealthChecks() async {
    Timer.periodic(Duration(minutes: 5), (timer) async {
      final isHealthy = await performHealthCheck();
      if (!isHealthy) {
        // Send notification or retry connection
        print('⚠️ Supabase health check failed, attempting recovery...');
      }
    });
  }
}
```

---

## 🚨 **EMERGENCY CONTACTS**

### **Supabase Support:**
- **Documentation**: https://supabase.com/docs
- **Community**: https://github.com/supabase/supabase/discussions
- **Discord**: https://discord.supabase.com
- **Email Support**: Available for paid plans

### **Quick Recovery Steps:**
1. **Check Supabase Status Page**: https://status.supabase.com
2. **Test API endpoints** using curl or Postman
3. **Check your project logs** in Supabase Dashboard
4. **Verify your API keys** are correct
5. **Test with a simple query** before complex operations

---

**🔧 Use this guide to diagnose and resolve Supabase issues quickly and effectively.** 