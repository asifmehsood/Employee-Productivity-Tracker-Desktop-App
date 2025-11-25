# 🔑 Azure Configuration Guide

## What You Need from Azure Portal

### Step 1: Get Your Azure Credentials

You need **3 pieces of information** from Azure:

1. **Storage Account Name**
2. **Access Key** (Primary or Secondary)
3. **Container Name** (the folder where screenshots will be stored)

---

## 📋 How to Get Azure Credentials

### 1️⃣ Go to Azure Portal
- Open: https://portal.azure.com
- Sign in with your Azure account

### 2️⃣ Navigate to Storage Account
1. Click **"Storage accounts"** in the left menu (or search for it)
2. Click on your storage account name
   - If you don't have one, click **"+ Create"** to make a new storage account

### 3️⃣ Get Storage Account Name
- **Where to find it**: At the top of the Storage Account page
- **Example**: `mycompanystorage` or `employeedata2024`
- **Copy this value** ✅

### 4️⃣ Get Access Key
1. In your Storage Account, look in the left menu
2. Under **"Security + networking"**, click **"Access keys"**
3. You'll see **key1** and **key2**
4. Click **"Show"** next to **key1**
5. Click the **copy icon** to copy the key
6. **Save this securely** - it's like a password! 🔐

### 5️⃣ Create Blob Container
1. In your Storage Account, look in the left menu
2. Under **"Data storage"**, click **"Containers"**
3. Click **"+ Container"** at the top
4. Enter name: `employee-screenshots` (or your preferred name)
5. Set **Public access level**: **Private** (recommended)
6. Click **"Create"**
7. **Copy the container name** ✅

---

## 🖥️ Where to Paste in the App

### Option 1: Through App Settings (Recommended)

1. **Run the app**:
   ```powershell
   flutter run -d windows
   ```

2. **First-time setup**: Enter your Employee ID and Name

3. **Go to Settings**:
   - Click the ⚙️ **Settings icon** in the top-right corner

4. **Fill in Azure Blob Storage section**:
   - **Storage Account Name**: Paste value from Step 3 above
   - **Access Key**: Paste value from Step 4 above
   - **Container Name**: Paste value from Step 5 above (default: `employee-screenshots`)

5. **Set Screenshot Interval**:
   - Move the slider (1-60 minutes, default: 5 minutes)

6. **Click Save** 💾

---

## 📝 Example Values

Here's what it looks like with example data:

```
Storage Account Name: mycompanystorage
Access Key: abcd1234EFGH5678ijkl9012MNOP3456qrst7890uvwx==
Container Name: employee-screenshots
Screenshot Interval: 5 minutes
```

---

## 🔒 Security Notes

⚠️ **IMPORTANT**:
- **Never share your Access Key publicly**
- It's like a password to your Azure storage
- Keep it secure and confidential
- You can rotate (change) keys in Azure Portal if needed

---

## ✅ Testing the Connection

After entering credentials in Settings:

1. Start a task in the app
2. Screenshots will capture automatically
3. Check your Azure Portal:
   - Go to Storage Account → Containers → employee-screenshots
   - You should see folders with task IDs
   - Inside: PNG screenshot files with timestamps

---

## 🔗 Screenshot URL Format

When uploaded, screenshots get a URL like:

```
https://mycompanystorage.blob.core.windows.net/employee-screenshots/screenshots/task-id/screenshot-id.png
```

Odoo (or any system) can access these URLs directly using the same Azure credentials.

---

## 🆘 Troubleshooting

### "Upload failed" error:
- ✅ Verify Storage Account Name is correct (no typos)
- ✅ Verify Access Key is the full key (including == at the end)
- ✅ Verify Container exists in Azure Portal
- ✅ Check internet connection

### Can't see screenshots in Azure:
- Wait 5-10 seconds for upload
- Refresh the Containers page in Azure Portal
- Check if local screenshots exist in: `Documents/Employee Productivity Tracker/screenshots/`

### Screenshots not capturing:
- On **macOS**: Grant Screen Recording permission
  - System Preferences → Security & Privacy → Screen Recording
- On **Windows**: Should work automatically
- Check screenshot interval isn't too long

---

## 📞 Need Help?

Common issues:
1. **Wrong credentials**: Double-check copy-paste
2. **Container doesn't exist**: Create it in Azure Portal
3. **Access denied**: Verify Access Key is from the correct Storage Account
4. **Network issues**: Check firewall/proxy settings

---

## 🎯 Quick Checklist

Before running the app:
- [ ] Azure Storage Account created
- [ ] Container created (e.g., `employee-screenshots`)
- [ ] Storage Account Name copied
- [ ] Access Key copied
- [ ] Container Name copied
- [ ] All values entered in app Settings
- [ ] Settings saved in app

Now you're ready to track productivity! 🚀
