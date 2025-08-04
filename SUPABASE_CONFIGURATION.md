# 🔧 Supabase Configuration & Table Structure

## 📋 Overview
This document details the complete Supabase configuration, table structure, and database schema for the CRM application.

---

## 🔗 **SUPABASE CONFIGURATION**

### **🌐 Project Details**
```yaml
Project Name: AluminumFormworkCRM
Project URL: https://vlapmwwroraolpgyfrtg.supabase.co
Project ID: vlapmwwroraolpgyfrtg
Region: Default (Auto-detected)
```

### **🔑 API Keys & Configuration**
```dart
// Supabase URL
static const String supabaseUrl = 'https://vlapmwwroraolpgyfrtg.supabase.co';

// Anonymous Key (Public)
static const String supabaseAnonKey = 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ';
```

### **🚀 Flutter Integration**
```dart
// Initialize Supabase in main.dart
await Supabase.initialize(
  url: 'https://vlapmwwroraolpgyfrtg.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsYXBtd3dyb3Jhb2xwZ3lmcnRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwNDE3NzQsImV4cCI6MjA2NzYxNzc3NH0.3nyd2GT9DD_FMFTsJyiEqAjTIH7uREQ8R-dcamXwenQ',
);

// Client instance
static final SupabaseClient client = SupabaseClient(
  supabaseUrl,
  supabaseAnonKey,
);
```

---

## 🗄️ **DATABASE TABLE STRUCTURE**

### **📋 1. LEADS TABLE**
```sql
CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Lead Information
  project_name TEXT NOT NULL,
  client_name TEXT,
  project_location TEXT,
  lead_type TEXT DEFAULT 'Monolithic Formwork',
  status TEXT DEFAULT 'new',
  
  -- Contact Information
  main_contact_name TEXT,
  main_contact_email TEXT,
  main_contact_mobile TEXT,
  
  -- User Assignment
  lead_generated_by UUID REFERENCES auth.users(id),
  
  -- Additional Details
  remark TEXT,
  total_amount DECIMAL(10,2) DEFAULT 0,
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  priority TEXT DEFAULT 'medium'
);

-- Indexes
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX idx_leads_lead_generated_by ON leads(lead_generated_by);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_lead_type ON leads(lead_type);
```

### **👥 2. USERS TABLE**
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- User Information
  username TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('Admin', 'Sales', 'Proposal Engineer', 'Developer', 'User')),
  
  -- Session Management
  session_active BOOLEAN DEFAULT false,
  session_id TEXT,
  last_active TIMESTAMP WITH TIME ZONE,
  online_status BOOLEAN DEFAULT false,
  
  -- Account Status
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  verification_code TEXT,
  
  -- Profile Information
  full_name TEXT,
  mobile_no TEXT,
  profile_picture TEXT,
  
  -- Settings
  preferences JSONB DEFAULT '{}',
  timezone TEXT DEFAULT 'UTC'
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(user_type);
CREATE INDEX idx_users_session_active ON users(session_active);
CREATE INDEX idx_users_is_active ON users(is_active);
```

### **👨‍💻 3. DEV_USER TABLE**
```sql
CREATE TABLE dev_user (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Developer Information
  username TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  user_type TEXT DEFAULT 'Developer',
  
  -- Session Management
  session_active BOOLEAN DEFAULT false,
  session_id TEXT,
  last_active TIMESTAMP WITH TIME ZONE,
  online_status BOOLEAN DEFAULT false,
  
  -- Account Status
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  verification_code TEXT,
  
  -- Developer Specific
  skills TEXT[],
  experience_level TEXT,
  assigned_projects TEXT[],
  
  -- Profile Information
  full_name TEXT,
  mobile_no TEXT,
  profile_picture TEXT
);

-- Indexes
CREATE INDEX idx_dev_user_email ON dev_user(email);
CREATE INDEX idx_dev_user_session_active ON dev_user(session_active);
CREATE INDEX idx_dev_user_is_active ON dev_user(is_active);
```

### **👥 4. LEAD_CONTACTS TABLE**
```sql
CREATE TABLE lead_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Contact Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  contact_name TEXT NOT NULL,
  designation TEXT,
  email TEXT,
  mobile TEXT,
  
  -- Additional Details
  company_name TEXT,
  department TEXT,
  notes TEXT,
  
  -- Metadata
  is_primary BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true
);

-- Indexes
CREATE INDEX idx_lead_contacts_lead_id ON lead_contacts(lead_id);
CREATE INDEX idx_lead_contacts_email ON lead_contacts(email);
```

### **📎 5. LEAD_ATTACHMENTS TABLE**
```sql
CREATE TABLE lead_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- File Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_link TEXT NOT NULL,
  file_size BIGINT,
  file_type TEXT,
  
  -- Upload Information
  uploaded_by UUID REFERENCES auth.users(id),
  upload_notes TEXT,
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  category TEXT DEFAULT 'general'
);

-- Indexes
CREATE INDEX idx_lead_attachments_lead_id ON lead_attachments(lead_id);
CREATE INDEX idx_lead_attachments_uploaded_by ON lead_attachments(uploaded_by);
CREATE INDEX idx_lead_attachments_file_type ON lead_attachments(file_type);
```

### **📈 6. LEAD_ACTIVITY TABLE**
```sql
CREATE TABLE lead_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Activity Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  activity_type TEXT NOT NULL,
  changes_made JSONB,
  
  -- Activity Details
  description TEXT,
  old_value TEXT,
  new_value TEXT,
  
  -- Metadata
  ip_address INET,
  user_agent TEXT
);

-- Indexes
CREATE INDEX idx_lead_activity_lead_id ON lead_activity(lead_id);
CREATE INDEX idx_lead_activity_user_id ON lead_activity(user_id);
CREATE INDEX idx_lead_activity_created_at ON lead_activity(created_at DESC);
CREATE INDEX idx_lead_activity_type ON lead_activity(activity_type);
```

### **💬 7. QUERIES TABLE**
```sql
CREATE TABLE queries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Query Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id),
  receiver_id UUID REFERENCES auth.users(id),
  sender_name TEXT NOT NULL,
  receiver_name TEXT NOT NULL,
  query_message TEXT NOT NULL,
  
  -- Message Details
  message_type TEXT DEFAULT 'text',
  attachments JSONB,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,
  
  -- Metadata
  priority TEXT DEFAULT 'normal',
  tags TEXT[]
);

-- Indexes
CREATE INDEX idx_queries_lead_id ON queries(lead_id);
CREATE INDEX idx_queries_sender_id ON queries(sender_id);
CREATE INDEX idx_queries_receiver_id ON queries(receiver_id);
CREATE INDEX idx_queries_created_at ON queries(created_at DESC);
```

### **📄 8. PROPOSAL_INPUT TABLE**
```sql
CREATE TABLE proposal_input (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Input Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  input TEXT NOT NULL,
  value TEXT NOT NULL,
  
  -- Additional Details
  remark TEXT,
  unit TEXT,
  category TEXT,
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  version INTEGER DEFAULT 1
);

-- Indexes
CREATE INDEX idx_proposal_input_lead_id ON proposal_input(lead_id);
CREATE INDEX idx_proposal_input_user_id ON proposal_input(user_id);
CREATE INDEX idx_proposal_input_input ON proposal_input(input);
```

### **📁 9. PROPOSAL_FILE TABLE**
```sql
CREATE TABLE proposal_file (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- File Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  file_name TEXT NOT NULL,
  file_link TEXT NOT NULL,
  file_size BIGINT,
  file_type TEXT,
  
  -- Proposal Details
  proposal_version TEXT,
  proposal_type TEXT DEFAULT 'technical',
  description TEXT,
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  is_approved BOOLEAN DEFAULT false,
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_proposal_file_lead_id ON proposal_file(lead_id);
CREATE INDEX idx_proposal_file_user_id ON proposal_file(user_id);
CREATE INDEX idx_proposal_file_proposal_type ON proposal_file(proposal_type);
```

### **💬 10. PROPOSAL_REMARK TABLE**
```sql
CREATE TABLE proposal_remark (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Remark Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  remark TEXT NOT NULL,
  
  -- Remark Details
  remark_type TEXT DEFAULT 'general',
  priority TEXT DEFAULT 'normal',
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  
  -- Metadata
  tags TEXT[]
);

-- Indexes
CREATE INDEX idx_proposal_remark_lead_id ON proposal_remark(lead_id);
CREATE INDEX idx_proposal_remark_user_id ON proposal_remark(user_id);
CREATE INDEX idx_proposal_remark_created_at ON proposal_remark(created_at DESC);
```

### **👨‍💼 11. ADMIN_RESPONSE TABLE**
```sql
CREATE TABLE admin_response (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Response Information
  lead_id UUID REFERENCES leads(id) ON DELETE CASCADE,
  admin_id UUID REFERENCES auth.users(id),
  project_id TEXT,
  
  -- Pricing Information
  rate_sqm DECIMAL(10,2),
  total_amount DECIMAL(10,2),
  currency TEXT DEFAULT 'USD',
  
  -- Response Details
  status TEXT DEFAULT 'pending',
  remark TEXT,
  response_type TEXT DEFAULT 'pricing',
  
  -- Approval Information
  is_approved BOOLEAN DEFAULT false,
  approved_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES auth.users(id),
  
  -- Metadata
  version INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true
);

-- Indexes
CREATE INDEX idx_admin_response_lead_id ON admin_response(lead_id);
CREATE INDEX idx_admin_response_admin_id ON admin_response(admin_id);
CREATE INDEX idx_admin_response_status ON admin_response(status);
```

### **📧 12. INVITATION TABLE**
```sql
CREATE TABLE invitation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Invitation Information
  user_name TEXT NOT NULL,
  email TEXT NOT NULL,
  mobile_no TEXT,
  user_type TEXT NOT NULL,
  
  -- Invitation Status
  active BOOLEAN DEFAULT false,
  is_registered BOOLEAN DEFAULT false,
  registered_at TIMESTAMP WITH TIME ZONE,
  
  -- Invitation Details
  invitation_code TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  invited_by UUID REFERENCES auth.users(id),
  
  -- Metadata
  notes TEXT,
  status TEXT DEFAULT 'pending'
);

-- Indexes
CREATE INDEX idx_invitation_email ON invitation(email);
CREATE INDEX idx_invitation_active ON invitation(active);
CREATE INDEX idx_invitation_user_type ON invitation(user_type);
```

### **⚙️ 13. SYSTEM_CONFIG TABLE**
```sql
CREATE TABLE system_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Configuration Information
  setting_name TEXT UNIQUE NOT NULL,
  setting_value TEXT,
  setting_type TEXT DEFAULT 'string',
  
  -- Configuration Details
  description TEXT,
  category TEXT DEFAULT 'general',
  is_active BOOLEAN DEFAULT true,
  
  -- Metadata
  updated_by UUID REFERENCES auth.users(id),
  version INTEGER DEFAULT 1
);

-- Indexes
CREATE INDEX idx_system_config_setting_name ON system_config(setting_name);
CREATE INDEX idx_system_config_category ON system_config(category);
CREATE INDEX idx_system_config_is_active ON system_config(is_active);
```

---

## 🔒 **ROW LEVEL SECURITY (RLS) POLICIES**

### **🛡️ Authentication Policies**
```sql
-- Enable RLS on all tables
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE queries ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_input ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_file ENABLE ROW LEVEL SECURITY;
ALTER TABLE proposal_remark ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_response ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitation ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;
```

### **👥 User Access Policies**
```sql
-- Users can only access their own data
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Admins can access all data
CREATE POLICY "Admins can access all data" ON leads
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type = 'Admin'
    )
  );
```

### **📋 Lead Access Policies**
```sql
-- Sales users can only access their own leads
CREATE POLICY "Sales users can access own leads" ON leads
  FOR ALL USING (
    lead_generated_by = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.user_type = 'Admin'
    )
  );

-- Proposal engineers can view all leads
CREATE POLICY "Proposal engineers can view leads" ON leads
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND (users.user_type = 'Proposal Engineer' OR users.user_type = 'Admin')
    )
  );
```

---

## 🔧 **DATABASE FUNCTIONS & TRIGGERS**

### **📅 Updated At Trigger**
```sql
-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_leads_updated_at 
    BEFORE UPDATE ON leads 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### **📊 Analytics Functions**
```sql
-- Function to get lead statistics
CREATE OR REPLACE FUNCTION get_lead_stats(user_id UUID)
RETURNS TABLE (
    total_leads BIGINT,
    new_leads BIGINT,
    in_progress_leads BIGINT,
    completed_leads BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_leads,
        COUNT(*) FILTER (WHERE status = 'new') as new_leads,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_leads,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_leads
    FROM leads
    WHERE lead_generated_by = user_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 🚀 **PERFORMANCE OPTIMIZATION**

### **📈 Indexes for Performance**
```sql
-- Composite indexes for common queries
CREATE INDEX idx_leads_user_status ON leads(lead_generated_by, status);
CREATE INDEX idx_leads_type_status ON leads(lead_type, status);
CREATE INDEX idx_users_type_active ON users(user_type, is_active);

-- Partial indexes for active records
CREATE INDEX idx_leads_active ON leads(id) WHERE is_active = true;
CREATE INDEX idx_users_active ON users(id) WHERE is_active = true;
```

### **💾 Storage Optimization**
```sql
-- Enable compression for large tables
ALTER TABLE lead_activity SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

-- Partition large tables by date
CREATE TABLE lead_activity_2024 PARTITION OF lead_activity
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

---

## 🔐 **SECURITY CONFIGURATION**

### **🔑 API Key Management**
```yaml
# Production Environment
SUPABASE_URL: https://vlapmwwroraolpgyfrtg.supabase.co
SUPABASE_ANON_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY: [Keep Secret - Server Only]

# Development Environment
SUPABASE_URL_DEV: https://your-dev-project.supabase.co
SUPABASE_ANON_KEY_DEV: [Development Key]
```

### **🛡️ Authentication Settings**
```sql
-- Configure JWT settings
ALTER DATABASE postgres SET "jwt.secret" = 'your-jwt-secret';
ALTER DATABASE postgres SET "jwt.exp" = '3600';

-- Enable email confirmation
UPDATE auth.config SET enable_signup = true;
UPDATE auth.config SET enable_confirmations = true;
UPDATE auth.config SET enable_email_change = true;
```

---

## 📊 **MONITORING & LOGGING**

### **📈 Database Monitoring**
```sql
-- Enable query logging
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_duration_statement = 1000;

-- Create audit log table
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id),
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT
);
```

---

## 🔄 **BACKUP & RECOVERY**

### **💾 Backup Strategy**
```bash
# Automated daily backups
pg_dump -h vlapmwwroraolpgyfrtg.supabase.co -U postgres -d postgres > backup_$(date +%Y%m%d).sql

# Backup specific tables
pg_dump -h vlapmwwroraolpgyfrtg.supabase.co -U postgres -d postgres -t leads -t users > critical_tables_backup.sql
```

---

**📚 This configuration provides a complete, secure, and optimized Supabase setup for the CRM application.** 