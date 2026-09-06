# Plan: Enhance Feature Improvements and Standout Features Document

**Status:** Completed

## Files to Change

- `plans/20260906_201800_enhance_feature_improvements_and_standout_doc.md` [NEW] - This implementation plan.
- `docs/feature_improvements_and_standout_features.md` [MODIFY] - Comprehensive enhancement of the feature improvements, architectural boundaries, standout differentiators, and cross-ecosystem synergies.

## Issue

The current `docs/feature_improvements_and_standout_features.md` provides an initial overview of feature improvements and standout capabilities. However, it needs to be elevated to match the production-grade depth, architectural rigor, and structural standards established across the 18 reference applications in the SreerajP ecosystem (such as `SreerajP_Journal_Vault`, `SreerajP_PDFApp`, `vault-files`, `sreeraj_qr_reader`, `sms-sentry`, and `SreerajPContactSphere`).

Specifically, the document requires:
1. Clear **Security Reality & Behavioral Boundaries** defining true hardware-backed cryptography vs. simulated privacy, Scoped Storage / MediaStore constraints, air-gapped local networking rules, and transparently disclosed architectural limitations.
2. Exhaustive, technically precise breakdowns for each module with underlying algorithms, SQLite triggers, background isolates, and Android platform APIs.
3. An explicit **SreerajP Ecosystem Interoperability** section connecting the gallery to the 18 companion apps (e.g., photo insertion into Journal Vault, batch export to PDFApp, QR safety verification with QR Reader, contact avatar assignment with ContactSphere, MMS inspection with SMS Sentry, ambient clock displays).
4. A multi-dimensional **Competitive Comparison Matrix** evaluating the gallery against OEM galleries, cloud monopolies, and ad-supported tools across privacy, portability, cryptography, and offline intelligence.
5. An expanded **Technical Stack & Constraints Table** and prioritized **Implementation Roadmap Matrix** spanning v1.1.0 to v1.5.0.

## Fix

Update `docs/feature_improvements_and_standout_features.md` with:
1. **Header & Context Governance**: Document links, source-of-truth baseline, and executive summary.
2. **Security Reality & Behavioral Boundaries**:
   - Hardware-backed StrongBox / Android Keystore AES-256-GCM encryption for the Private Vault.
   - Scoped Storage and MediaStore mutation boundaries (granular permissions, atomic operations, zero legacy `MANAGE_EXTERNAL_STORAGE`).
   - Air-gapped local network transport boundaries (`LocalAddressRules`, strictly local subnet sockets, ephemeral X25519 handshakes).
   - Optical air-gapped data transmission boundaries (AirQR camera-to-screen streams with zero RF emission).
   - Disclosed gaps and platform constraints (flash memory wear-leveling caveats, MediaStore pre-import indexing window).
3. **Exhaustive Module-by-Module Improvement Catalog**:
   - Timeline, Grid & Smart Memory Browsing (Heatmap/Calendar overlay, offline vector maps, year/decade pinch zoom, Ken Burns flashback player, burst shot grouping).
   - Fullscreen Viewer & Pro Video Player (PiP, A/B side-by-side synchronized comparison, magnifier loupe, subtitle & multi-track audio switcher, background audio playback).
   - Studio-Grade Non-Destructive Editor (Spline RGB curves, selective gradient/radial masks, HSL 8-channel tuner, custom recipes with import/export, hold-to-compare original, perspective rectification, true privacy redaction).
   - Video Utilities, Document Tools & Format Conversion (Lossless stream-copy audio extractor, video audio muter/stripper, animated WebP/APNG builder, motion photo player & splitter, batch PDF rasterizer with Malayalam font embedding).
   - Search, Intelligence, Tagging & OCR Engine (On-device SQLite FTS5 index for in-image OCR text, bilingual Malayalam + English offline OCR with Unicode first-strong direction detection, k-means color search, perceptual hashing pHash+dHash duplicate cleaner, blurry/dark scanner, storage hog analyzer).
   - Album Management, Hierarchies & Dynamic Rules (Multi-level nested albums, compound rule-based dynamic albums, soft-hidden albums with biometric gate, dynamic cycling album covers).
   - Military-Grade Hardware-Backed Vault (StrongBox Keystore AES-256-GCM, Decoy/Duress PIN, in-vault categorization, stealth calculator disguise mode, direct encrypted camera capture, `FLAG_SECURE` window protection, multi-pass file shredder).
   - Local Sync, Backups & Optical AirQR (Serverless local P2P Wi-Fi sync, AirQR optical streaming without any network, universal `.gallerybak` encrypted container with 4-tier re-linking, incremental differential backup archives, private LAN WebDAV/SMB backup).
   - Media Privacy, EXIF Scrubber & Geofence Shifting (One-tap complete EXIF scrubber, GPS geofence shifter with randomized 2–5 km city-level offset, forensic metadata inspector).
4. **SreerajP App Ecosystem Interoperability & Synergies**:
   - Concrete integration workflows across all 18 reference applications in the user's workspace.
5. **Standout Capabilities & Industry Comparison Matrix**:
   - Comprehensive comparative evaluation across 14 key dimensions.
6. **Key Technical Facts & Dependency Constraints**:
   - Framework, SDKs, architecture layers, storage rules, and blocked dependencies.
7. **Implementation Feasibility & Roadmap Matrix**:
   - Prioritized roadmap matrix categorizing each feature by effort, impact, prerequisites, and target release milestone (v1.1.0 to v1.5.0).
