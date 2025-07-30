# Repository Secrets Setup Guide

This guide will help you properly configure your GitHub repository secrets to fix the "Context access might be invalid" warnings.

## 🔧 Required Secrets

You need to configure the following secrets in your GitHub repository:

### 1. SUPABASE_ACCESS_TOKEN
- **Purpose**: Authentication token for Supabase CLI
- **How to get it**:
  1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
  2. Click on your profile icon → "Account"
  3. Go to "Access Tokens" tab
  4. Click "Generate new token"
  5. Give it a name (e.g., "GitHub Actions")
  6. Copy the generated token

### 2. SUPABASE_DB_PASSWORD
- **Purpose**: Database password for your Supabase project
- **How to get it**:
  1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
  2. Select your project: **tobler-crm**
  3. Go to "Settings" → "Database"
  4. Look for "Database password" or "Connection string"
  5. Copy the password from the connection string

### 3. SUPABASE_DB_URL
- **Purpose**: Complete database connection URL
- **Format**: `postgresql://postgres:[PASSWORD]@db.vlapmwwroraolpgyfrtg.supabase.co:5432/postgres`
- **How to get it**:
  1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
  2. Select your project: **tobler-crm**
  3. Go to "Settings" → "Database"
  4. Look for "Connection string" or "Connection pooling"
  5. Copy the full connection string

## 📝 Setting Up Secrets in GitHub

### Step 1: Access Repository Settings
1. Go to your GitHub repository: `https://github.com/aaryesha17/AluminumFormworkCRM`
2. Click on "Settings" tab
3. In the left sidebar, click "Secrets and variables" → "Actions"

### Step 2: Add Each Secret
For each secret below, click "New repository secret" and add:

#### Secret 1: SUPABASE_ACCESS_TOKEN
- **Name**: `SUPABASE_ACCESS_TOKEN`
- **Value**: Your Supabase access token (from step 1 above)

#### Secret 2: SUPABASE_DB_PASSWORD
- **Name**: `SUPABASE_DB_PASSWORD`
- **Value**: Your database password (from step 2 above)

#### Secret 3: SUPABASE_DB_URL
- **Name**: `SUPABASE_DB_URL`
- **Value**: Your complete database URL (from step 3 above)

## 🔍 Verification Steps

### Step 1: Check Current Secrets
1. Go to your repository settings
2. Navigate to "Secrets and variables" → "Actions"
3. Verify all three secrets are present:
   - ✅ SUPABASE_ACCESS_TOKEN
   - ✅ SUPABASE_DB_PASSWORD
   - ✅ SUPABASE_DB_URL

### Step 2: Test the Configuration
1. Make a small change to your code
2. Push to the `develop` branch
3. Check the GitHub Actions tab
4. Verify the deployment job runs without errors

## 🚨 Troubleshooting

### If you still see warnings:
1. **Refresh your IDE**: Close and reopen VS Code
2. **Clear cache**: Restart your development environment
3. **Check secret names**: Ensure exact spelling and case
4. **Verify permissions**: Make sure the secrets are accessible

### Common Issues:
- **Secret not found**: Double-check the secret name spelling
- **Access denied**: Ensure you have admin access to the repository
- **Invalid token**: Regenerate your Supabase access token

## 📋 Secret Values Reference

Your Supabase project details:
- **Project ID**: `vlapmwwroraolpgyfrtg`
- **Project Name**: `tobler-crm`
- **Region**: `ap-south-1`
- **Database Host**: `db.vlapmwwroraolpgyfrtg.supabase.co`

## ✅ Success Indicators

After proper setup, you should see:
- ✅ No more "Context access might be invalid" warnings
- ✅ Successful CI/CD pipeline runs
- ✅ Successful deployments to Supabase
- ✅ Clean GitHub Actions logs

## 🔐 Security Notes

- Never commit secrets to your repository
- Use repository secrets for sensitive data
- Regularly rotate your access tokens
- Monitor secret usage in GitHub Actions logs 