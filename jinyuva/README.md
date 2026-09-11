# JinYuva Registration Website

Mobile-first JinYuva registration site matching the supplied cream/olive/gold visual identity.

## Included flow

1. Poster QR opens the site.
2. User selects English, Gujarati, or Hindi.
3. Required fields: Name, Phone, DOB, Sangh.
4. User confirms details.
5. Server calculates age from DOB (the form does not trust a typed age).
6. Age 10–30 → youth WhatsApp link; age 31+ → 31+ WhatsApp link.
7. A unique JinYuva ID and random public token are created.
8. Membership card shows Name, JinYuva ID, Age, Sangh, WhatsApp button, and personal QR.
9. Scanning the personal QR opens that member's card.
10. Registering the same phone again returns the existing membership instead of creating a duplicate.

## Configure Supabase

1. Create a Supabase project.
2. Open SQL Editor and run `sql/schema.sql`.
3. Copy `config.example.js` to `config.js` (already present as a template) and fill in:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` (public anon key only)
   - `WHATSAPP_YOUTH_LINK`
   - `WHATSAPP_31_PLUS_LINK`
   - `CONTACT_PHONE`
4. Deploy the folder to any static host (Vercel, Netlify, GitHub Pages with the right setup, etc.).
5. The database can be exported from Supabase as CSV and opened in Excel. Keep phone/DOB data private when sharing.

## Important

- The phone number is unique internally, but the public/member-facing ID is `JY-xxxxxx`.
- No OTP is included in this first version, so phone ownership is not verified. The system prevents duplicate registrations using the phone number stored in the database.
- Age is calculated from DOB on the database server.
- Replace placeholder WhatsApp links/contact number before launch.
