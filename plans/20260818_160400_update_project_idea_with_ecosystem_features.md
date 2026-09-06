# Plan: Update Project Idea with Ecosystem Features

**Status:** Implemented

## 1. Issue & Objective
The `docs/Project_Idea.md` document outlines the core specification for the Image & Video Gallery app. Based on the analysis of the ecosystem apps, we need to incorporate several new capabilities into `docs/Project_Idea.md`:
- Offline Intelligence: In-Image QR & Barcode Scanner, Offline OCR, and Perceptual Duplicate & Similar Photo Finder.
- PDF Utilities: Extract Embedded Images from PDF files.
- Vault & Privacy Upgrades: Hardware-backed AES-256-GCM encryption with Android Keystore, Anti-Forensic Secure Shredding (zero-fill overwrite), and native `FLAG_SECURE` window protection.
- Smart Timeline & Organization: "On This Day" Flashback Memories engine, Media Notes & Markdown Attachments, and Full-Text SQLite (FTS5) search.
- Connectivity & Data Portability: Zero-Cloud Peer-to-Peer (P2P) Local Wi-Fi Sync and Encrypted Full Backup & Restore (`.gallerybak`).
- Architecture, Accessibility & Safety: Bi-directional Multi-Script UI (English & Malayalam), Atomic File Operations (`AtomicSaver`), and RAM-aware memory allocation policy (`system_info2`).

## 2. Files to Change
- `docs/Project_Idea.md` (Modify)

## 3. Detailed Proposed Changes

### Section 2.1: Media Viewing & Browsing
- Add **"On This Day" / Flashback Memories Engine**: Automatic banner/carousel at the top of the timeline highlighting media captured on today's date in past years (1 year ago, 2 years ago, etc.).
- Add **Extract Embedded Images from PDFs**: Browse PDF files and extract high-resolution photos or illustrations into the gallery.

### Section 2.2: Fullscreen Viewer & Media Intelligence
- Add **In-Image QR & Barcode Scanner**: Scan and detect QR codes, barcodes, and Wi-Fi codes directly from any image or video frame with one-tap actions (copy, connect to Wi-Fi, open URL, view vCard).
- Add **Offline OCR (Optical Character Recognition)**: Extract selectable text, phone numbers, and addresses from photos with copy, search, and share actions.
- Add **Media Notes & Markdown Attachments**: Attach custom formatted notes, reminders, or markdown descriptions to any photo or video.

### Section 2.7 & 2.8: Search, Tagging & Organization
- Add **Full-Text SQLite (FTS5) Search Engine**: Instant search across filenames, tags, album names, user notes, EXIF camera metadata, and locations.
- Add **Visual Duplicate & Similar Photo Finder (Perceptual Hashing)**: Group exact duplicates (SHA-256) and visually similar photos (pHash / dHash) in a cleanup screen with side-by-side comparison and "Keep Best / Delete Rest" assistant.

### Section 2.9: Secure Private Vault
- Enhance **Hardware-Backed AES-256-GCM Encryption**: Android Keystore integration for cryptographic key management and AES-256-GCM encryption.
- Add **Anti-Forensic Secure Shredding (Zero-Fill Overwrite)**: Multi-pass overwrite of file bytes before unlinking during vault import or permanent deletion.
- Add **FLAG_SECURE Native Window Protection**: Prevent screenshots, screen recording, and blur app previews in the Android app switcher.

### Section 2.11: Data Portability & Device-to-Device Sync
- Add **Zero-Cloud Peer-to-Peer (P2P) Local Wi-Fi Sync**: Direct transfer of photos/videos and metadata between devices on the same local network using sockets and QR pairing.
- Add **Encrypted Full Backup & Restore**: Backup tags, virtual albums, metadata edits, and favorites into a password-protected `.gallerybak` archive.

### Section 3 & 4: UI/UX & Technical Architecture
- Add **Bi-directional Multi-Script Inclusion (English & Malayalam)**: Support for Malayalam (`ml`) and English (`en`) with `detectTextDirection` and `AdaptiveDirectionality`.
- Add **Atomic File Operations (`AtomicSaver`)**: Write edits and conversions to temp files first before atomic swap to prevent corruption.
- Add **RAM-Aware Memory Allocation Policy (`system_info2`)**: Query device RAM to dynamically scale thumbnail caches and video buffers to prevent OOM errors.
- Update Technical Stack table with new components (`google_mlkit_text_recognition` / offline OCR, `mobile_scanner` / ZXing, `crypto` / `pHash`, `system_info2`, `fts5`).

## 4. Verification Plan
- Verify that `docs/Project_Idea.md` contains all requested features structured logically.
- Ensure formatting is consistent with the rest of the documentation.
- Maintain simple English and strict offline privacy guarantees.
