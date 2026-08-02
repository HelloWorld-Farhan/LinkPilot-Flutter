# 📬 LinkPilot – Complete AI Development Prompt

<p align="center">
  <img src="assets/Logo.png" width="120" alt="LinkPilot Logo" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Isar_DB-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
  <img src="https://img.shields.io/badge/Google_Apps_Script-4285F4?style=for-the-badge&logo=google&logoColor=white"/>
  <img src="https://img.shields.io/badge/License-MIT-brightgreen?style=for-the-badge"/>
</p>

<p align="center">
  <strong>LinkPilot</strong> is a beautiful, highly polished link scheduling app built in Flutter. It features smart company name parsing from URLs, PDF report generation, seamless local storage to persist your history, and custom integrations to generate and send reports automatically via Google Apps Script without human interaction.
</p>

---

## ✨ Features

- **Automated Backend Processing:** Securely generates PDF reports and sends emails via a deployed Google Apps Script.
- **Smart URL Parsing:** Automatically extracts the company or brand name from job links (e.g. `careers.microsoft.com` → `Microsoft`).
- **Advanced PDF Generation:** Instantly builds clean, modern PDF documents with clickable links.
- **Permanent History:** All generated reports and processed links are permanently saved to a beautifully animated History directory.
- **Sender Auto-Complete:** Securely memorizes your sender email and persists settings across launches.
- **Stunning Modern UI:** Built with a vibrant Primary Blue and Clean White aesthetic, featuring `flutter_animate` staggered lists and silky smooth bouncing scroll physics.
- **Local Storage Engine:** Utilizing Isar Database and SharedPreferences to keep all scheduled data persistently saved on your device offline.
- **Daily Reminders:** WorkManager powered daily notifications at 12:00 AM if you have pending links.

---

## 📥 Backend Setup (Google Apps Script)

LinkPilot requires a Google Apps Script deployment to handle PDF generation, Google Drive uploading, and Email sending. 
Please refer to the `gas_setup.md` file located in the project documentation or setup instructions for the exact script and manual deployment steps.

---

## 💻 How to Build (For Developers)

Before you begin, ensure you have the **Flutter SDK** installed on your system.

### Step 1 — Clone the Repository
```bash
git clone https://github.com/HelloWorld-Farhan/LinkPilot-Flutter.git
cd LinkPilot-Flutter
```

### Step 2 — Fetch Dependencies
```bash
flutter pub get
```

### Step 3 — Generate Isar Models
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4 — Run Locally
```bash
flutter run
```

### Step 5 — Build the APK Release
```bash
flutter build apk --release
```
*Your `app-release.apk` file will be generated inside `build/app/outputs/flutter-apk/`.*

---

## 👨‍💻 Author

**Farhan Khalid**  
📧 farhankhalid17968@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/farhan-khalid-117514259/)  
🐙 [GitHub](https://github.com/HelloWorld-Farhan)  

---

## 📄 License

```text
MIT License

Copyright (c) 2026 Farhan Khalid

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🌟 Support

If you found this app helpful, please consider giving it a ⭐ on GitHub!

<p align="center">Made with ❤️ in India</p>
