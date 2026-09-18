// JinYuva configuration
const JINYUVA_CONFIG = {
  SUPABASE_URL: 'https://vpuulwfsgrpstxshitpi.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_Z5B5-EdOb6YkEZyMKJRzpg_BkSGRRKB',

  WHATSAPP_YOUTH_LINK: 'https://chat.whatsapp.com/GNhrFsGNdJLGhODIAA6yHi',
  WHATSAPP_31_PLUS_LINK: 'https://chat.whatsapp.com/L82yFLryPEU42dmrnd84sx',
  INSTAGRAM_LINK: 'https://www.instagram.com/jinyuva?stkn=cHg4cmk2ZnQ3eHdn',

  CONTACT_PHONE: '8591919468'
};

// Create the Supabase client
if (
  JINYUVA_CONFIG.SUPABASE_URL &&
  JINYUVA_CONFIG.SUPABASE_ANON_KEY &&
  !JINYUVA_CONFIG.SUPABASE_URL.includes('YOUR-') &&
  !JINYUVA_CONFIG.SUPABASE_ANON_KEY.includes('YOUR_')
) {
  window.supabaseClient = window.supabase.createClient(
    JINYUVA_CONFIG.SUPABASE_URL,
    JINYUVA_CONFIG.SUPABASE_ANON_KEY
  );
}