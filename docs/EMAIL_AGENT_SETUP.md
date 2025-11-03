# Agent Email Intelligent LX Studio - Guide d'installation

## Vue d'ensemble

Workflow n8n complet pour gérer automatiquement les emails entrants sur contact@lxstudio.ch avec IA (Claude/Anthropic).

**Fonctionnalités:**
- ✅ Lecture IMAP automatique
- ✅ Classification d'intention (info/devis/support/autre)
- ✅ Réponses multilingues (FR/EN/DE/IT)
- ✅ Extraction automatique de données lead
- ✅ Questions itératives pour compléter les informations
- ✅ Génération de devis PDF professionnel
- ✅ Envoi automatique par SMTP
- ✅ Journalisation CRM (Supabase/Notion)

---

## 🔧 Prérequis

### 1. n8n self-hosted
- Version: **1.17+**
- Installation: https://docs.n8n.io/hosting/

### 2. Comptes & API requis
- **Email IMAP/SMTP** (Gmail, Outlook, mail custom)
- **Anthropic API** (Claude) - https://console.anthropic.com/
- **Supabase** (database gratuite) - https://supabase.com/
- **Optionnel**: Stripe (paiements), Notion (CRM alternatif)

---

## 📦 Installation rapide

### Étape 1: Importer le workflow

1. Ouvrir n8n
2. Aller dans **Workflows** > **Import from File**
3. Sélectionner: `workflows/email-agent-intelligent.json`
4. Cliquer **Import**

### Étape 2: Configurer les Credentials n8n

#### A) IMAP (lecture emails)

1. Dans n8n: **Settings** > **Credentials** > **New**
2. Choisir: **IMAP**
3. Remplir:
   - **User**: `contact@lxstudio.ch`
   - **Password**: `[votre app-password]`
   - **Host**: `imap.gmail.com` (ou votre serveur)
   - **Port**: `993`
   - **SSL**: ✅ activé
4. **Test & Save**

**Note Gmail**: Activer "App Password" dans https://myaccount.google.com/apppasswords

#### B) SMTP (envoi emails)

1. **New Credential** > **SMTP**
2. Remplir:
   - **User**: `contact@lxstudio.ch`
   - **Password**: `[votre app-password]`
   - **Host**: `smtp.gmail.com`
   - **Port**: `587` (STARTTLS) ou `465` (SSL)
   - **From Email**: `contact@lxstudio.ch`
3. **Test & Save**

#### C) Anthropic API (Claude)

1. Aller sur: https://console.anthropic.com/settings/keys
2. Créer une **API Key**
3. Dans n8n: **New Credential** > **Anthropic API**
4. Coller la clé API
5. **Save**

#### D) Supabase (base de données)

1. Créer un compte sur https://supabase.com/
2. Créer un nouveau **Project**
3. Aller dans **Settings** > **API**
4. Noter:
   - **Project URL**: `https://xxx.supabase.co`
   - **anon/public key**: `eyJhbG...`
5. Dans n8n: **New Credential** > **Header Auth**
   - **Name**: `Supabase Auth`
   - **Header Name**: `apikey`
   - **Value**: `[votre anon key]`
   - Ajouter header: `Authorization: Bearer [votre anon key]`
6. **Save**

### Étape 3: Créer la table Supabase

Exécuter ce SQL dans **Supabase SQL Editor**:

```sql
CREATE TABLE leads (
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
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'waiting_user', 'quoted', 'closed')),
  completeness_score NUMERIC DEFAULT 0,
  can_quote_now BOOLEAN DEFAULT false,
  last_message_id TEXT,
  last_reply_draft TEXT,
  questions_sent JSONB,
  questions_sent_at TIMESTAMPTZ,
  quote_number TEXT,
  quote_amount NUMERIC,
  quote_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherches rapides
CREATE INDEX idx_leads_thread_key ON leads(thread_key);
CREATE INDEX idx_leads_email ON leads(email);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_created_at ON leads(created_at DESC);

-- Optionnel: table historique des échanges
CREATE TABLE email_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_key TEXT REFERENCES leads(thread_key),
  message_id TEXT NOT NULL,
  direction TEXT CHECK (direction IN ('in', 'out')),
  subject TEXT,
  body TEXT,
  intent TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Étape 4: Configurer les variables d'environnement

Dans n8n, ajouter ces variables d'env (Settings > Variables):

```bash
# SMTP
SMTP_FROM=contact@lxstudio.ch
SALES_CC=tanguy@lxstudio.ch

# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...

# Entreprise
SITE_URL=https://lxstudio.ch
TEL=+41 XX XXX XX XX
CAL_URL=https://cal.com/lxstudio/15min

# Optionnel: Stripe
STRIPE_SECRET_KEY=sk_live_...
```

**Ou** dans votre `.env` si n8n est en Docker:

```env
N8N_ENV_SMTP_FROM=contact@lxstudio.ch
N8N_ENV_SALES_CC=tanguy@lxstudio.ch
N8N_ENV_SUPABASE_URL=https://xxx.supabase.co
N8N_ENV_SITE_URL=https://lxstudio.ch
N8N_ENV_TEL=+41 XX XXX XX XX
N8N_ENV_CAL_URL=https://cal.com/lxstudio/15min
```

### Étape 5: Mapper les Credentials dans le workflow

1. Ouvrir le workflow importé
2. Pour chaque nœud avec erreur "Credential not set":
   - Cliquer sur le nœud
   - Sélectionner la credential correspondante dans le dropdown
3. Nœuds à configurer:
   - **IMAP Email Trigger** → IMAP credential
   - **Anthropic Orchestrator** → Anthropic API credential
   - **Upsert Lead to DB** → Supabase Auth (Header Auth)
   - Tous les nœuds **Send Email** → SMTP credential
   - **Update Lead Status** → Supabase Auth

### Étape 6: Activer le workflow

1. Cliquer sur **Active** (switch en haut à droite)
2. Le workflow commence à écouter les emails entrants

---

## ⚙️ Configuration avancée

### Modifier la grille de prix

Éditer le fichier: `templates/pricing-config.json`

```json
{
  "site_vitrine": {
    "base": 2500,
    "per_page": 300,
    "cms": 800
  },
  "agent_ia": {
    "email_automation": 1500,
    "chatbot": 2000
  }
}
```

**Puis** éditer le nœud **Calculate Quote** dans n8n:
- Copier/coller les nouvelles valeurs dans la variable `pricing`

### Personnaliser les templates email

Les emails sont générés dans:
- **Anthropic Orchestrator** (nœud HTTP) → `system` prompt → signature
- **Send Info Email**, **Send Clarification Questions**, etc. → field `message`

Modifier directement dans le nœud ou créer des templates HTML externes.

### Personnaliser le template PDF

Le PDF est généré dans le nœud **Generate PDF HTML** (Code node).

Modifier:
- Couleurs (CSS `#2563eb` = bleu LX)
- Logo (ajouter `<img src="...">`)
- Structure (lignes du tableau)

---

## 🧪 Scénarios de test

### Test 1: Demande d'informations

**Email entrant:**
```
De: client@example.com
Sujet: Tarifs site vitrine
Corps: Bonjour, quels sont vos tarifs pour un site vitrine ?
```

**Comportement attendu:**
- Intent détecté: `info`
- Réponse automatique avec fourchette de prix
- Status lead: `closed`

### Test 2: Demande de devis incomplète

**Email entrant:**
```
De: client@example.com
Sujet: Devis site web
Corps: Je veux un site 5 pages pour entreprise de nettoyage.
```

**Comportement attendu:**
- Intent: `devis`
- `can_quote_now: false`
- Email avec 3-6 questions ciblées (budget, délai, fonctionnalités)
- Status: `waiting_user`

### Test 3: Demande de devis complète

**Email entrant:**
```
De: client@example.com
Sujet: Devis site vitrine
Corps: Bonjour, je suis Sophie Müller, entreprise CleanPro Sàrl.
Je souhaite un site vitrine 5 pages (accueil, services, équipe, contact, blog).
Budget: 3000-4000 CHF. Délai souhaité: 4 semaines.
Avec formulaire de contact et optimisation SEO de base.
```

**Comportement attendu:**
- Intent: `devis`
- `can_quote_now: true`
- Génération automatique du devis PDF
- Email avec PDF en pièce jointe
- Status: `quoted`

### Test 4: Support client

**Email entrant:**
```
De: client-existant@example.com
Sujet: Site ne charge plus
Corps: Bonjour, mon site lxclient.ch ne charge plus depuis ce matin.
```

**Comportement attendu:**
- Intent: `support`
- Réponse empathique avec prochaines étapes
- (Idéalement: webhook vers ticket support)

### Test 5: Multilingue

**Email en anglais:**
```
Subject: Website quote
Body: Hi, I need a 3-page website for my business. Budget around 2500 CHF.
```

**Comportement attendu:**
- Langue détectée: `en`
- Réponse en anglais
- Questions en anglais si info manquante

---

## 🔄 Gestion des réponses clients (boucle clarification)

### Problème: Comment gérer les réponses aux questions de clarification ?

**Solution A: IMAP Trigger #2 (recommandé)**

Dupliquer le nœud IMAP et filtrer par `In-Reply-To`:

```javascript
// Node: Filter Reply Emails (Code)
const items = [];
for (const item of $input.all()) {
  const inReplyTo = item.json.inReplyTo || item.json.references || '';

  // Check if reply to our previous message
  // (compare with last_message_id stored in DB)
  if (inReplyTo.includes('message-id-from-db')) {
    items.push(item);
  }
}
return items;
```

**Solution B: Webhook + Forwarding**

Configurer une règle de forwarding Gmail:
- Si email avec `In-Reply-To: <our-message>`
- Alors forward vers webhook n8n

**Solution C: Polling régulier**

Ajouter un nœud **Schedule Trigger** (toutes les 5 min) qui:
1. Lit les emails UNSEEN
2. Vérifie si `In-Reply-To` match un lead en `waiting_user`
3. Re-passe par l'orchestrateur IA avec lead existant

---

## 📊 Suivi & Analytics

### Dashboard Supabase

Créer des vues SQL:

```sql
-- Leads par statut
SELECT status, COUNT(*) FROM leads GROUP BY status;

-- Taux de conversion
SELECT
  COUNT(CASE WHEN status = 'quoted' THEN 1 END) * 100.0 / COUNT(*) as conversion_rate
FROM leads
WHERE intent = 'devis';

-- Montant total devis envoyés
SELECT SUM(quote_amount) FROM leads WHERE status = 'quoted';
```

### Notifications Telegram (optionnel)

Ajouter un nœud **Telegram** après **Send Quote Email**:

```
Message:
🎉 Nouveau devis envoyé !
Client: {{ $json.lead.prenom }} {{ $json.lead.nom }}
Montant: {{ $json.quote.total_ttc }} CHF
```

---

## 🐛 Dépannage

### Erreur: "IMAP connection failed"

- Vérifier que l'app password est correct
- Tester avec `telnet imap.gmail.com 993`
- Vérifier que IMAP est activé dans Gmail Settings

### Erreur: "Anthropic API rate limit"

- Passer à un plan payant Anthropic
- Ou réduire `max_tokens` à 2048

### Erreur: "JSON parse failed"

- Le prompt système force un JSON strict
- Si échec, le node **Parse Anthropic Response** a un fallback
- Vérifier les logs dans Anthropic Console

### PDF ne se génère pas

- Vérifier que le nœud **HTML** (Convert to PDF) est bien configuré
- Option: utiliser une API externe (PDFMonkey, DocRaptor)

### Email non envoyé

- Vérifier SMTP credentials
- Tester avec un outil: https://www.smtper.net/
- Vérifier `SMTP_FROM` est bien une adresse autorisée

---

## 🚀 Améliorations futures

### 1. Paiement d'acompte (Stripe)

Après **Send Quote Email**, ajouter:

```javascript
// Node: Create Stripe Payment Link
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const paymentLink = await stripe.paymentLinks.create({
  line_items: [{
    price_data: {
      currency: 'chf',
      product_data: { name: 'Acompte 30% - ' + $json.quote.quote_number },
      unit_amount: Math.round($json.quote.total_ttc * 0.30 * 100)
    },
    quantity: 1
  }]
});

return { json: { ...item.json, payment_url: paymentLink.url } };
```

Insérer `payment_url` dans l'email de devis.

### 2. Webhook Stripe → Confirmation paiement

Créer un webhook n8n qui écoute `payment_intent.succeeded`:
- Mettre à jour lead status = `paid_deposit`
- Envoyer email de confirmation
- Créer tâche dans ClickUp/Notion

### 3. Multi-canal (WhatsApp, Telegram)

Dupliquer la logique pour:
- **WhatsApp Business API** (Twilio, 360dialog)
- **Telegram Bot** (nœud Telegram Trigger)

### 4. Historique conversationnel

Modifier le prompt Anthropic pour inclure l'historique:

```javascript
const history = await fetchFromDB(thread_key);
const messages = [
  { role: 'user', content: history.message1 },
  { role: 'assistant', content: history.reply1 },
  { role: 'user', content: currentEmail }
];
```

### 5. Validation humaine

Ajouter un nœud **Wait** avant **Send Quote Email**:
- Envoyer notification Slack/Telegram
- Attendre validation (Approve/Reject)
- Si Approve → envoi, sinon → édition manuelle

---

## 📖 Ressources

- **n8n docs**: https://docs.n8n.io/
- **Anthropic API**: https://docs.anthropic.com/
- **Supabase docs**: https://supabase.com/docs
- **Regex tester**: https://regex101.com/
- **Markdown preview**: https://dillinger.io/

---

## 📄 Licence

Workflow propriétaire © LX Studio 2025.
Utilisation autorisée pour LX Studio uniquement.

---

## 👤 Support

Pour toute question:
- **Email**: tanguy@lxstudio.ch
- **GitHub Issues**: (si repo privé)
- **Doc interne**: Notion LX Studio

**Version**: 1.0.0
**Dernière mise à jour**: 2025-01-03
