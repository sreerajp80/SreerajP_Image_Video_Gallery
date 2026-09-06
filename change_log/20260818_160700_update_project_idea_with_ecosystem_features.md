# Change Log: Update Project Idea with Ecosystem Features

**Date:** 2026-08-18  
**Plan:** `plans/20260818_160400_update_project_idea_with_ecosystem_features.md`

## Overview
Updated `docs/Project_Idea.md` to incorporate high-value features, security mechanisms, and architecture patterns identified across the Flutter applications ecosystem.

## Changes Made
- **Media Viewing & Timeline (`docs/Project_Idea.md` §2.1):**
  - Added "On This Day" / Flashback Memories engine for rediscovering past memories.
  - Added Embedded Image Extraction from PDF files.
- **Media Intelligence & Scanner (`docs/Project_Idea.md` §2.3):**
  - Added In-Image QR & Barcode Scanner with direct actions (Wi-Fi, URL, text, vCard).
  - Added Offline OCR (Optical Character Recognition) for text selection and copying.
  - Added Media Notes & Markdown Attachments for photos and videos.
- **Search, Tagging & Duplicate Cleaner (`docs/Project_Idea.md` §2.8):**
  - Added Full-Text SQLite (FTS5) search across filenames, tags, album names, notes, and metadata.
  - Added Visual Duplicate & Similar Photo Finder using SHA-256 and Perceptual Hashing (`pHash`/`dHash`).
- **Secure Private Vault (`docs/Project_Idea.md` §2.10):**
  - Upgraded encryption to True Hardware-Backed AES-256-GCM using Android Keystore.
  - Added Anti-Forensic Secure Shredding (zero-fill overwrite).
  - Added native `FLAG_SECURE` window protection.
- **Data Portability & Offline Sharing (`docs/Project_Idea.md` §2.11):**
  - Added Zero-Cloud Peer-to-Peer (P2P) Local Wi-Fi Sync.
  - Added Encrypted Full Backup & Restore (`.gallerybak`).
- **UI/UX, Architecture & Safety (`docs/Project_Idea.md` §3, §4, §5):**
  - Added Bi-directional Multi-Script Inclusion (English & Malayalam) with text direction detection.
  - Added Atomic File Operations (`AtomicSaver`) to safeguard against file corruption.
  - Added RAM-Aware Memory Allocation Policy (`system_info2`) for dynamic thumbnail cache scaling.
  - Updated Technical Architecture table and Security guarantees.

## Verification
- Verified `docs/Project_Idea.md` for consistent formatting, clear categorization, and adherence to 100% offline, privacy-first guarantees.
