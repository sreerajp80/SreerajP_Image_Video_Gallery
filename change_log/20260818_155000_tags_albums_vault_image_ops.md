# Tags, Custom Albums, Secure Vault, and Comprehensive Image Operations Change Log

**Plan Reference:** `plans/20260818_155000_tags_albums_vault_image_ops.md`  
**Date:** 2026-08-18

## Changes Made
- **Comprehensive Image Operations & Editor (Section 2.4)**: Expanded non-destructive image tools to include crop (preset/custom aspect ratios), 90° rotation, fine-angle straightening (-45° to +45°), horizontal/vertical flip, perspective skew correction, exposure/brightness/contrast/highlights/shadows tuning, temperature/tint/vibrance/clarity/vignette adjustments, RGB & individual color channel curve editors, artistic filters, freehand doodle brush, geometric shape callouts, text overlay, sensitive area privacy redaction (blur/pixelate/blackout), customizable text/timestamp/logo watermarks, and EXIF metadata stripping.
- **Photo & Video Tagging System (Section 2.7)**: Added specifications for creating, color-coding, editing, and deleting custom tags, universal tag assignment for both photos and videos, and multi-tag filtering with `AND` / `OR` search conditions.
- **Album Management & Organization (Section 2.8)**: Added user-created custom virtual albums (create, rename, delete, custom cover photo, item reordering) alongside physical device folder grouping and smart auto-albums.
- **Secure Private Vault (Section 2.9)**: Added offline private media vault protected with Biometric/PIN authentication, local AES-256 encryption, complete isolation from Android MediaStore indexing, `FLAG_SECURE` window protection, and zero external cache leakage.
- **Batch Operations (Section 2.10)**: Expanded batch actions to include tagging, album assignment, and secure vault moves.
- **Architecture & Security Guarantees (Sections 4 & 5)**: Updated technical stack with `flutter_secure_storage` / AES-256 encryption engine, `local_auth` biometric prompt, and explicit private vault security guarantees.
