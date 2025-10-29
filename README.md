# LX Studio - Plateforme d'Automatisation n8n

Suite complète de workflows n8n pour automatiser les opérations marketing, commerciales et de contenu de LX Studio, agence web en Suisse romande.

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Workflows](#workflows)
- [Base de données](#base-de-données)
- [Sécurité](#sécurité)
- [Maintenance](#maintenance)

---

## 🎯 Vue d'ensemble

Cette suite d'automatisation permet à LX Studio de :

- **Traiter automatiquement les demandes de devis par email** → Extraction LLM → Devis Stripe → Envoi
- **Gérer les acceptations de devis** → Facture Stripe → Email confirmation
- **Générer du contenu blog SEO** → Claude Sonnet → WordPress → Réseaux sociaux
- **Traiter les appels téléphoniques Twilio** → Transcription → Analyse intent → SMS recap
- **Publier sur les réseaux sociaux** → LinkedIn, Facebook, Instagram, X/Twitter
- **Automatiser la prospection B2B** → Personnalisation LLM → Envoi batch → Opt-out

### Caractéristiques principales

- ✅ **Zéro clé en clair** : Toutes les credentials sont référencées par nom
- ✅ **Idempotence** : Hash SHA256 pour éviter les doublons d'événements
- ✅ **Logging complet** : Supabase + Telegram pour monitoring
- ✅ **Rate limiting** : Contrôle du débit pour prospection
- ✅ **Localisation CH** : Français Suisse, CHF, cantons romands
- ✅ **Production-ready** : Gestion d'erreurs, retry, fallbacks

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    LX-Orchestrator (Hub)                    │
│  Webhook central → Idempotence → Switch → Execute Workflow │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐   ┌──────────────────┐   ┌──────────────┐
│ Email-To-Quote│   │   Blog-Auto      │   │Voice-Reception│
│ IMAP → Claude │   │ Cron → Claude    │   │Twilio→ Claude│
│ → Stripe Quote│   │ → WordPress      │   │→ SMS + Email │
└───────────────┘   └──────────────────┘   └──────────────┘
        │                     │
        ▼                     ▼
┌───────────────┐   ┌──────────────────┐
│ Quote-Accept  │   │Social-Publisher  │
│ Webhook→Stripe│   │Multi-platform    │
│→Invoice+Email │   │LinkedIn/FB/IG/X  │
└───────────────┘   └──────────────────┘
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
          ┌──────────────────┐  ┌────────────────┐
          │Email-Prospecting │  │  Supabase DB   │
          │Cron Daily→Claude │  │  PostgreSQL    │
          │→SMTP Batch+Optout│  │ Events/Errors  │
          └──────────────────┘  └────────────────┘
```

---

## 📦 Installation

### Prérequis

- **n8n** >= 1.60 (self-hosted ou cloud)
- **Supabase** (PostgreSQL + API)
- **Stripe** (compte actif, API keys)
- **WordPress** (avec REST API activée)
- **Twilio** (pour téléphonie, optionnel)
- **Anthropic Claude** (API key)
- **SMTP/IMAP** (Infomaniak, Gmail, etc.)
- **Telegram Bot** (pour notifications)
- **Comptes réseaux sociaux** : Meta, LinkedIn, X/Twitter (optionnel)

### Étapes d'installation

#### 1. Base de données Supabase

```bash
# Connectez-vous à votre projet Supabase
# Exécutez le schéma SQL complet
psql $SUPABASE_DB_URL -f lxo_schema.sql
```

#### 2. Variables d'environnement n8n

Copiez `env.sample` vers `.env` et remplissez toutes les valeurs :

```bash
cp env.sample .env
nano .env  # ou votre éditeur préféré
```

Variables **obligatoires** :
- `BASE_URL_N8N`
- `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY`
- `ANTHROPIC_API_KEY`
- `SMTP_*` et `IMAP_*` (pour email)
- `STRIPE_API_KEY`
- `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID`

Variables **optionnelles** (selon features) :
- `TWILIO_*` (si téléphonie)
- `META_*`, `LINKEDIN_*`, `X_*` (si social media)
- `WP_*` (si blog WordPress)

#### 3. Credentials n8n

Créez les credentials suivantes dans n8n (Settings → Credentials) :

| Nom credential | Type n8n | Variables env utilisées |
|----------------|----------|-------------------------|
| `Supabase-LX` | Supabase | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` |
| `SMTP-LX` | SMTP | `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` |
| `IMAP-LX` | IMAP | `IMAP_HOST`, `IMAP_USER`, `IMAP_PASSWORD` |
| `Stripe-LX` | Stripe API | `STRIPE_API_KEY` |
| `Anthropic-LX` | Anthropic (Claude) | `ANTHROPIC_API_KEY` |
| `Telegram-LX` | Telegram | `TELEGRAM_BOT_TOKEN` |
| `WP-LX` | WordPress | `WP_URL`, `WP_USERNAME`, `WP_APPLICATION_PASSWORD` |
| `Twilio-LX` | HTTP Basic Auth | `TWILIO_ACCOUNT_SID` (user), `TWILIO_AUTH_TOKEN` (password) |
| `HTTP-LX` | HTTP Header Auth | Tokens Meta/LinkedIn/X selon besoin |

#### 4. Import des workflows

Dans n8n :
1. **Workflows → Import from File**
2. Importez dans cet ordre :
   - `workflow_LX-Orchestrator.json` (obligatoire en premier)
   - `workflow_LX-Email-To-Quote.json`
   - `workflow_LX-Quote-Accept.json`
   - `workflow_LX-Blog-Auto.json`
   - `workflow_LX-Voice-Reception.json`
   - `workflow_LX-Social-Publisher.json`
   - `workflow_LX-Email-Prospecting.json`

3. **Activez chaque workflow** après vérification

---

## ⚙️ Configuration

### Webhooks publics

Configurez ces webhooks dans vos services externes :

| Service | Webhook URL | Workflow |
|---------|-------------|----------|
| **Orchestrator** | `BASE_URL_N8N/webhook/lx/orchestrate` | LX-Orchestrator |
| **Quote Accept** | `BASE_URL_N8N/webhook/lx/quote/accept?lead_id={ID}` | LX-Quote-Accept |
| **Twilio Voice** | `BASE_URL_N8N/webhook/lx/voice/inbound` | LX-Voice-Reception |
| **Social Publish** | `BASE_URL_N8N/webhook/lx/social/publish` | LX-Social-Publisher |
| **Blog Generate** | `BASE_URL_N8N/webhook/lx/blog/generate` | LX-Blog-Auto |
| **Unsubscribe** | `BASE_URL_N8N/webhook/lx/unsubscribe` | LX-Email-Prospecting |

### Twilio Configuration

Dans Twilio Console :
1. **Phone Numbers → Active Number → Configure**
2. **Voice & Fax → A call comes in** :
   - Webhook : `BASE_URL_N8N/webhook/lx/voice/inbound`
   - HTTP POST
3. **Enable Recording + Transcription**

### WordPress Configuration

Activez REST API :
1. **Settings → Permalinks** : Choisir "Post name"
2. **Users → Application Passwords** : Générer pour l'utilisateur n8n
3. Tester : `curl -u username:app_password https://lxstudio.ch/wp-json/wp/v2/posts`

---

## 📊 Workflows

### 1. LX-Orchestrator (Hub central)

**Trigger** : Webhook `/webhook/lx/orchestrate`

**Flow** :
1. Génère hash d'idempotence (SHA256)
2. Vérifie si événement déjà traité (Supabase)
3. Switch selon `event.kind` :
   - `email` → LX-Email-To-Quote
   - `voice` → LX-Voice-Reception
   - `blog` → LX-Blog-Auto
   - `social` → LX-Social-Publisher
   - `prospect` → LX-Email-Prospecting
   - `stripe` → Handler Stripe (inline)
4. Log événement + Telegram notify

**Payload exemple** :
```json
{
  "event": {
    "kind": "email",
    "id": "msg_12345",
    "data": { ... }
  }
}
```

---

### 2. LX-Email-To-Quote

**Trigger** : IMAP (mailbox INBOX, filter `to:contact@lxstudio.ch`)

**Flow** :
1. **Extract email text** (binary → text)
2. **Basic extraction** : Détection langue + regex email/phone
3. **Claude Haiku** : Extraction structurée (contact, project, metadata)
4. **Upsert contact** + **Insert lead** (Supabase)
5. **Build pricing** : Calcul selon barème + multiplicateurs
6. **Stripe Create Quote** : Génération devis avec montant TTC
7. **Insert quote** (Supabase)
8. **Send email** : SMTP avec lien acceptation
9. **Move to Processed** : IMAP folder
10. **Log event** + **Telegram notify**

**Barème tarifaire** (configuré dans Code node) :
- Site vitrine : 2'500 CHF base
- E-commerce : 5'000 CHF base
- Application custom : 8'000 CHF base
- Multiplicateurs : multilingue (+20%), paiement (+30%), API (+25%), etc.

**Erreurs** → Supabase `errors` table + Telegram alert

---

### 3. LX-Quote-Accept

**Trigger** : Webhook GET `/webhook/lx/quote/accept?lead_id={UUID}`

**Flow** :
1. **Verify parameters** : lead_id + hash security (optionnel)
2. **Get quote details** : JOIN quotes/leads/contacts
3. **If quote exists** :
   - **Stripe Create Invoice** (draft)
   - **Add line item** (montant du devis)
   - **Finalize invoice**
   - **Insert invoice** (Supabase)
   - **Update quote** status → `accepted`
   - **Update lead** status → `converted`
   - **Send invoice email** : SMTP avec lien paiement
   - **Telegram notify** : Conversion réussie
4. **Else** : Page erreur "Devis introuvable"
5. **Response** : HTML page de confirmation

**Sécurité** : Hash SHA256 optionnel sur lead_id pour éviter abus

---

### 4. LX-Blog-Auto

**Triggers** :
- Cron weekly (automatique)
- Webhook POST `/webhook/lx/blog/generate` (manuel)

**Flow** :
1. **Generate SEO brief** : Sélection aléatoire topic (secteur, geo, keywords)
2. **Claude Sonnet** : Génération article complet (1200-1800 mots, SEO optimisé)
3. **Parse article JSON** : title, slug, content_markdown, meta_description, schema_org
4. **WordPress Create Post** : Publication directe (status=publish)
5. **Insert blog_post** (Supabase)
6. **Ping sitemap** : Google notification
7. **Trigger Social Publisher** : Execute workflow pour cross-posting
8. **Telegram notify** : Confirmation publication

**Topics configurés** (dans Code node) :
- PME Vaud (site web PME Lausanne)
- E-commerce Genève
- Startup Romandie (MVP, tech)
- Automatisation Suisse (n8n, workflows)
- SEO Lausanne (référencement local)

**Personnalisation** : Éditez le node "Generate SEO Brief" pour ajouter vos topics

---

### 5. LX-Voice-Reception

**Trigger** : Webhook POST `/webhook/lx/voice/inbound` (Twilio)

**Flow** :
1. **Parse Twilio payload** : CallSid, From, To, Status, RecordingUrl
2. **If has transcript** : Utilise transcription fournie
3. **Else** : Fetch transcription depuis Twilio API
4. **Merge transcript**
5. **Claude Haiku** : Analyse intent + urgency + sentiment + summary
6. **Find contact** by phone (Supabase)
7. **If not exists** : Create contact
8. **Insert voice_call** (Supabase)
9. **Send SMS recap** : Twilio avec réponse suggérée
10. **Email recap to team** : SMTP vers contact@lxstudio.ch
11. **Telegram notify** : Alerte si action requise

**Intents détectés** :
- `demande_devis` (lead hot/warm/cold)
- `support_technique`
- `information`
- `reclamation`
- `autre`

**Urgency levels** : `low`, `medium`, `high`, `critical`

---

### 6. LX-Social-Publisher

**Trigger** : Webhook POST `/webhook/lx/social/publish` ou call depuis LX-Blog-Auto

**Payload** :
```json
{
  "blog_post_id": "uuid",
  "blog_title": "Titre article",
  "blog_excerpt": "Résumé...",
  "blog_url": "https://lxstudio.ch/slug"
}
```

**Flow** :
1. **Parse payload**
2. **Claude Haiku** : Génère 3 posts adaptés (LinkedIn, FB/IG, X/Twitter)
3. **Parse posts JSON**
4. **Post to platforms** (parallèle) :
   - **Facebook** : Meta Graph API
   - **LinkedIn** : REST API v2
   - **X/Twitter** : Thread de 3 tweets (API v2)
5. **Log social_posts** (Supabase) pour chaque plateforme
6. **Telegram notify** : Confirmation multi-plateformes

**Formats générés** :
- **LinkedIn** : Post professionnel 1300 chars max, hashtags 3-5
- **Facebook/Instagram** : Post storytelling 2200 chars, hashtags 8-15
- **X/Twitter** : Thread 3 tweets (hook, insights, CTA+lien)

---

### 7. LX-Email-Prospecting

**Triggers** :
- Cron daily (automatique)
- Webhook `/webhook/lx/unsubscribe` (opt-out handler)

**Flow prospection** :
1. **Get Romandie prospects** : Query Supabase
   - Cantons : VD, GE, NE, FR, VS, JU
   - opted_out = false
   - Non contactés depuis 30 jours
   - LIMIT = `PROSPECT_DAILY_LIMIT` (env var, défaut 50)
2. **Split in batches** : Lots de `PROSPECT_BATCH_SIZE` (défaut 10)
3. **For each prospect** :
   - **Claude Haiku** : Personnalisation email (80-140 mots)
   - **Parse email JSON** : subject, body, preview_text
   - **Add footer** : Signature + lien opt-out avec hash
   - **Send email** : SMTP
   - **Log sent email** (Supabase `prospect_emails`)
4. **Wait between batches** : `PROSPECT_BATCH_DELAY_SECONDS` (défaut 40s)
5. **Loop** jusqu'à fin ou quota atteint
6. **Telegram notify** : Rapport fin de campagne

**Flow opt-out** :
1. **Webhook GET** `/webhook/lx/unsubscribe?email={email}&hash={hash}`
2. **Verify hash** : SHA256 security check
3. **Mark as opted out** : Supabase update `contacts.opted_out = true`
4. **Response** : HTML page de confirmation

**Rate limiting** :
- 50-80 emails/jour recommandé
- Pause 40s entre lots de 10
- Respect RGPD/CAN-SPAM : Lien opt-out obligatoire dans chaque email

---

## 🗄️ Base de données

Le schéma Supabase (`lxo_schema.sql`) comprend :

### Tables principales

#### `contacts`
- Stocke tous les contacts (prospects, clients, leads)
- Champs : email (unique), first_name, last_name, phone, company, canton, opted_out
- Indexé sur : email, canton, opted_out

#### `leads`
- Opportunités commerciales liées aux contacts
- Champs : contact_id (FK), status, priority, service_type, score
- Status : `new`, `contacted`, `qualified`, `quoted`, `converted`, `lost`

#### `quotes`
- Devis générés via Stripe
- Champs : lead_id (FK), stripe_quote_id, amount_chf, status, accept_url
- Status : `draft`, `sent`, `accepted`, `declined`, `expired`

#### `invoices`
- Factures Stripe suite à acceptation devis
- Champs : quote_id (FK), stripe_invoice_id, amount_chf, payment_url
- Status : `draft`, `open`, `paid`, `void`

#### `blog_posts`
- Articles de blog publiés sur WordPress
- Champs : wp_post_id, title, slug, content, seo_keywords, published_at

#### `social_posts`
- Publications sur réseaux sociaux
- Champs : blog_post_id (FK), platform, platform_post_id, content, hashtags

#### `voice_calls`
- Appels téléphoniques Twilio
- Champs : contact_id (FK), twilio_call_sid, transcript, intent, summary

#### `prospect_emails`
- Emails de prospection envoyés
- Champs : contact_id (FK), subject, body, status, sent_at, opened_at

#### `events`
- Log de tous les événements traités
- Champs : event_hash (unique), kind, entity_type, entity_id, status
- **Idempotence** : `event_hash` unique garantit pas de doublon

#### `errors`
- Log de toutes les erreurs workflows
- Champs : workflow_name, node_name, error_message, severity, resolved

### Vues utiles

#### `v_active_leads`
- Leads actifs (non converted/lost) avec infos contact

#### `v_prospect_stats`
- Statistiques campagnes prospection (open_rate, reply_rate)

### RLS (Row Level Security)

Activé sur toutes les tables. Par défaut : policy "Allow service role full access".

**Important** : Configurez les policies selon votre setup auth Supabase.

---

## 🔒 Sécurité

### Bonnes pratiques implémentées

1. **Aucune credential en clair** : Toutes stockées dans n8n Credentials Manager
2. **Hash secrets** : Variable `HASH_SECRET` pour idempotence et opt-out
3. **HTTPS obligatoire** : Tous les webhooks doivent être en HTTPS
4. **Rate limiting** : Prospection contrôlée (batch + delay)
5. **Opt-out systématique** : Lien désabonnement dans chaque email prospection
6. **Validation input** : Tous les webhooks vérifient les paramètres requis
7. **Error handling** : Try/catch dans Code nodes + error workflows
8. **Supabase RLS** : Row Level Security activée (à configurer selon auth)

### Variables sensibles

Stockez dans n8n Environment Variables (Settings → Variables) :

**Obligatoires** :
- `HASH_SECRET` : Secret pour hash idempotence/opt-out (générer aléatoire)
- Toutes les API keys (Stripe, Anthropic, Twilio, etc.)

**Recommandées** :
- `SENTRY_DSN` : Pour monitoring erreurs (optionnel)
- `ERROR_NOTIFICATION_EMAIL` : Email backup pour alertes

### Audit & Monitoring

- **Supabase `events` table** : Traçabilité complète des événements
- **Supabase `errors` table** : Historique erreurs avec stack traces
- **Telegram notifications** : Alertes temps réel (succès + erreurs)
- **n8n Execution logs** : Rétention selon votre plan (7 jours → illimité)

---

## 🛠️ Maintenance

### Tâches régulières

#### Quotidien
- ✅ Vérifier notifications Telegram (erreurs critiques)
- ✅ Monitorer quota prospection (limite 50-80/jour)

#### Hebdomadaire
- ✅ Review Supabase `errors` table → Résoudre récurrentes
- ✅ Check leads status → Suivis manuels si nécessaire
- ✅ Vérifier publications blog/social (qualité contenu)

#### Mensuel
- ✅ Analyser stats prospection (`v_prospect_stats` view)
- ✅ Nettoyer contacts opted_out depuis >1 an (RGPD)
- ✅ Review pricing barème (ajuster multiplicateurs si besoin)
- ✅ Backup Supabase (automatique si tier payant)

### Logs & Troubleshooting

#### Où chercher en cas d'erreur ?

1. **n8n Execution log** (workflow concerné) : Premier niveau, voir quel node fail
2. **Supabase `errors` table** : `SELECT * FROM errors WHERE workflow_name = '...' ORDER BY created_at DESC`
3. **Telegram historique** : Notifications temps réel avec context
4. **Stripe Dashboard** : Si problème paiement/quote/invoice
5. **Twilio Console** : Si problème voice calls

#### Erreurs courantes

| Erreur | Cause probable | Solution |
|--------|---------------|----------|
| `Missing credential` | Credential n8n non configurée | Vérifier Settings → Credentials |
| `Invalid API key` | Token expiré ou incorrect | Regénérer + mettre à jour credential |
| `Duplicate event_hash` | Event déjà traité (normal) | Ignorer (idempotence fonctionnelle) |
| `Query timeout` | Supabase overload | Vérifier connexions + query optimization |
| `SMTP send failed` | Quota/blacklist | Vérifier logs provider (Infomaniak, etc.) |
| `Stripe 400 error` | Paramètre invalide dans API call | Check input data + Stripe logs |

### Mises à jour

#### Workflows
1. Exporter workflow modifié depuis n8n (JSON)
2. Commit dans ce repo
3. Tester sur environnement staging avant prod
4. Activer nouveau workflow + désactiver ancien
5. Monitorer executions 24h

#### Credentials
1. Générer nouveau token/key dans service source
2. Mettre à jour credential n8n (Settings → Credentials → Edit)
3. Tester workflow concerné
4. Supprimer ancien token dans service source (si supporté)

#### Database schema
1. Écrire migration SQL (`ALTER TABLE ...`)
2. Appliquer sur Supabase staging
3. Tester workflows impactés
4. Appliquer sur Supabase production
5. Commit migration dans `/migrations/` (créer dossier)

---

## 📚 Ressources

### Documentation

- **n8n** : https://docs.n8n.io/
- **Supabase** : https://supabase.com/docs
- **Stripe API** : https://stripe.com/docs/api
- **Anthropic Claude** : https://docs.anthropic.com/
- **Twilio** : https://www.twilio.com/docs
- **WordPress REST API** : https://developer.wordpress.org/rest-api/

### Prompts & Templates

Tous les prompts LLM sont documentés dans `prompts.md`.
Tous les templates email sont dans `email_templates.md`.

**Personnalisation** :
- Éditez les prompts pour ajuster le ton/style
- Testez via Claude Workbench avant de déployer
- Versionnez les prompts (git) pour rollback si besoin

### Support

**Issues** : Ouvrir un ticket sur ce repo GitHub
**Email** : contact@lxstudio.ch
**Telegram** : Notifications configurées dans workflows

---

## 📄 Licence

Propriétaire © LX Studio 2025. Tous droits réservés.

Ce code est fourni à des fins de démonstration et d'usage interne uniquement.

---

## 🙏 Crédits

- **n8n** : Workflow automation platform
- **Anthropic Claude** : LLM pour extraction, génération, analyse
- **Supabase** : Backend PostgreSQL + Auth + Storage
- **Stripe** : Paiements + devis + factures
- **Twilio** : Téléphonie cloud + SMS

Généré avec ❤️ par **Claude Code**

---

**Version** : 1.0.0
**Dernière mise à jour** : 2025-01-XX
**Compatibilité n8n** : >= 1.60
**Compatibilité Supabase** : PostgreSQL 14+

---

## 🚀 Quick Start

```bash
# 1. Clone ce repo
git clone https://github.com/lxstudio/n8n-workflows.git
cd n8n-workflows

# 2. Setup Supabase
psql $SUPABASE_DB_URL -f lxo_schema.sql

# 3. Configure .env
cp env.sample .env
nano .env  # Remplir toutes les variables

# 4. Configure n8n credentials
# Via UI : Settings → Credentials → Add Credential

# 5. Import workflows
# Via UI : Workflows → Import from File

# 6. Activer workflows
# Via UI : Chaque workflow → Active toggle ON

# 7. Tester
# Webhook test : curl -X POST $BASE_URL_N8N/webhook/lx/orchestrate -d '{"event":{"kind":"test"}}'
```

---

**Prêt à automatiser ! 🎉**
