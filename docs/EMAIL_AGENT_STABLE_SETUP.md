# Agent Email Intelligent LX Studio - Version Stable

## 🎯 Version corrigée compatible n8n v1.20+

Cette version corrige tous les problèmes de compatibilité:
- ✅ Pas de nœud HTML→PDF non supporté
- ✅ Pas de credential Anthropic non standard
- ✅ Envoi PDF en pièce jointe fonctionnel
- ✅ Uniquement des nœuds core n8n

---

## 📦 Installation rapide

### 1. Importer le workflow

```bash
# Dans n8n
Workflows → Import from File → email-agent-intelligent-stable.json
```

### 2. Créer les credentials n8n

#### A) IMAP (lecture emails)

1. **Settings → Credentials → New Credential**
2. Type: **IMAP**
3. Name: `IMAP_ACCOUNT`
4. Configuration:
   - User: `contact@lxstudio.ch`
   - Password: `[votre app-password Gmail]`
   - Host: `imap.gmail.com`
   - Port: `993`
   - SSL/TLS: ✅ Activé

**Note Gmail**: Créer un App Password sur https://myaccount.google.com/apppasswords

#### B) SMTP (envoi emails)

1. **Settings → Credentials → New Credential**
2. Type: **SMTP**
3. Name: `SMTP_ACCOUNT`
4. Configuration:
   - User: `contact@lxstudio.ch`
   - Password: `[même app-password]`
   - Host: `smtp.gmail.com`
   - Port: `587` (ou 465 pour SSL)
   - SSL/TLS: ✅ Activé

### 3. Configurer les variables d'environnement

Dans **Settings → Variables** (ou fichier `.env` si Docker):

```bash
# Anthropic API (obligatoire)
ANTHROPIC_API_KEY=sk-ant-api03-...

# SMTP
SMTP_FROM=contact@lxstudio.ch

# Supabase (obligatoire)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Service PDF (choisir une option ci-dessous)
PDF_SERVICE_URL=https://api.html2pdfrocket.com/pdf
PDF_SERVICE_API_KEY=votre_clé_api_pdf

# Alternative: PDFShift
# PDF_SERVICE_URL=https://api.pdfshift.io/v3/convert/pdf
# PDF_SERVICE_API_KEY=votre_clé_pdfshift

# Alternative: CloudConvert
# PDF_SERVICE_URL=https://api.cloudconvert.com/v2/convert
# PDF_SERVICE_API_KEY=votre_clé_cloudconvert
```

### 4. Créer la table Supabase

Exécuter ce SQL dans **Supabase SQL Editor**:

```sql
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_key TEXT UNIQUE NOT NULL,
  email TEXT,
  nom TEXT,
  prenom TEXT,
  telephone TEXT,
  entreprise TEXT,
  service_demande TEXT,
  description_projet TEXT,
  budget_montant NUMERIC,
  budget_devise TEXT DEFAULT 'CHF',
  delai_souhaite TEXT,
  intent TEXT CHECK (intent IN ('info', 'devis', 'support', 'autre')),
  language TEXT CHECK (language IN ('fr', 'en', 'de', 'it')),
  status TEXT DEFAULT 'open',
  completeness_score NUMERIC DEFAULT 0,
  can_quote_now BOOLEAN DEFAULT false,
  last_message_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_leads_thread_key ON leads(thread_key);
CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_status ON leads(status);
```

### 5. Choisir et configurer un service PDF

Le workflow nécessite un service externe pour convertir HTML en PDF. Voici les options:

#### Option A: html2pdfrocket.com (Recommandé)

1. S'inscrire sur https://www.html2pdfrocket.com/
2. Obtenir API key
3. Configurer dans n8n:
   ```bash
   PDF_SERVICE_URL=https://api.html2pdfrocket.com/pdf
   PDF_SERVICE_API_KEY=votre_clé
   ```

#### Option B: PDFShift.io

1. S'inscrire sur https://pdfshift.io/
2. Obtenir API key
3. Modifier le nœud "Convert HTML to PDF":
   ```json
   {
     "url": "https://api.pdfshift.io/v3/convert/pdf",
     "headers": {
       "Authorization": "Basic {{ Buffer.from($env.PDF_SERVICE_API_KEY + ':').toString('base64') }}"
     },
     "body": {
       "source": "{{ $json.pdf_html }}",
       "format": "A4"
     }
   }
   ```

#### Option C: CloudConvert

1. S'inscrire sur https://cloudconvert.com/
2. Créer API key
3. Configuration plus complexe (multi-étapes)

#### Option D: Community Node (sans service externe)

Si vous préférez ne pas utiliser de service externe:

1. Installer le community node:
   ```bash
   npm install n8n-nodes-puppeteer
   # ou dans n8n UI: Settings → Community Nodes → Install
   ```

2. Remplacer le nœud "Convert HTML to PDF" par:
   - Type: `n8n-nodes-puppeteer.puppeteer`
   - Operation: `HTML to PDF`
   - HTML: `{{ $json.pdf_html }}`

### 6. Mapper les credentials dans le workflow

1. Ouvrir le workflow importé
2. Pour chaque nœud avec ⚠️:
   - **IMAP Email Trigger** → Sélectionner `IMAP_ACCOUNT`
   - **Send Info Email** → Sélectionner `SMTP_ACCOUNT`
   - **Send Quote Email** → Sélectionner `SMTP_ACCOUNT`
   - **Send Clarification Email** → Sélectionner `SMTP_ACCOUNT`
   - **Send Support Email** → Sélectionner `SMTP_ACCOUNT`
   - **Send Other Email** → Sélectionner `SMTP_ACCOUNT`

### 7. Activer le workflow

1. Cliquer sur **Active** (toggle en haut à droite)
2. Le workflow commence à écouter les emails

---

## 🧪 Tests

### Test 1: Demande d'informations

Envoyer un email à `contact@lxstudio.ch`:

```
Sujet: Tarifs site web
Corps: Bonjour, quels sont vos tarifs pour un site vitrine ?
```

**Résultat attendu**: Réponse automatique avec infos tarifs

### Test 2: Devis incomplet

```
Sujet: Devis site
Corps: Je souhaite un site 5 pages pour mon entreprise de nettoyage
```

**Résultat attendu**: Email avec questions (budget? délai? fonctionnalités?)

### Test 3: Devis complet

```
Sujet: Devis site vitrine
Corps: Bonjour, je suis Sophie Müller de CleanPro Sàrl.
Je souhaite un site vitrine 5 pages avec formulaire de contact et SEO.
Budget: 3500 CHF
Délai: 4 semaines
```

**Résultat attendu**: PDF de devis généré et envoyé par email

### Test 4: Multilingue (English)

```
Subject: Website quote
Body: Hi, I need a 3-page website for my startup. Budget around 2500 CHF.
```

**Résultat attendu**: Réponse en anglais

---

## 🔧 Personnalisation

### Modifier la grille de prix

Éditer le nœud **Calculate Quote** (Code):

```javascript
const pricing = {
  site_vitrine: {
    base: 2500,        // ← Modifier ici
    per_page: 300,     // ← Prix par page
    cms: 800,
    seo_base: 500,
    forms: 400
  },
  // ... etc
};
```

### Modifier le template PDF

Éditer le nœud **Generate PDF HTML** (Code):

```javascript
const html = `
<!DOCTYPE html>
<html>
<head>
  <style>
    /* Modifier le CSS ici */
    .logo { color: #2563eb; } /* Couleur logo */
  </style>
</head>
<body>
  <!-- Modifier le HTML ici -->
</body>
</html>
`;
```

### Modifier les emails de réponse

Les emails sont générés par Claude dans le nœud **Claude Analysis**.

Pour modifier le style/ton, éditer le `system` prompt:

```
Tu es l'agent email intelligent de LX Studio...
[Ajouter vos instructions ici]
```

---

## 🐛 Dépannage

### Erreur: "Missing ANTHROPIC_API_KEY"

**Solution**: Vérifier que la variable d'env est définie dans Settings → Variables

### Erreur: "PDF service failed"

**Solutions**:
1. Vérifier que `PDF_SERVICE_URL` et `PDF_SERVICE_API_KEY` sont corrects
2. Tester l'API manuellement avec curl
3. Vérifier le quota/crédit du service PDF
4. Utiliser une alternative (PDFShift, CloudConvert)

### Erreur: "Attachment not found"

**Solution**: Vérifier que le nœud "Set PDF Binary" est bien configuré:
- Mode: `jsonToBinary`
- Output property: `data`

### Email non envoyé

**Solutions**:
1. Vérifier SMTP credentials
2. Tester avec: https://www.smtper.net/
3. Vérifier que Gmail App Password est valide
4. Vérifier que `SMTP_FROM` est autorisé

### Erreur Supabase "401 Unauthorized"

**Solution**: Vérifier que `SUPABASE_ANON_KEY` est correct (pas le service_role_key)

---

## 📊 Différences avec la version précédente

| Aspect | Version originale | Version stable |
|--------|------------------|----------------|
| Nœud PDF | `n8n-nodes-base.html` (non supporté) | HTTP Request vers service externe |
| Claude API | Credential `anthropicApi` (non standard) | HTTP Request avec headers manuels |
| Attachments | `attachments: "{{ filename }}"` | `attachmentsBinary: [{ property: "data" }]` |
| Compatibilité | n8n 1.60+ seulement | n8n 1.20+ (stable) |

---

## 🚀 Prochaines améliorations

- [ ] Boucle de réponse automatique (détection In-Reply-To)
- [ ] Intégration Stripe Payment Links
- [ ] Dashboard analytics
- [ ] Validation humaine optionnelle
- [ ] Support WhatsApp/Telegram

---

## 📄 Support

- **Documentation n8n**: https://docs.n8n.io/
- **Anthropic API**: https://docs.anthropic.com/
- **Supabase**: https://supabase.com/docs
- **Email**: contact@lxstudio.ch

---

**Version**: 1.0.0-stable
**Dernière mise à jour**: 2025-01-03
**Compatibilité**: n8n >= 1.20
