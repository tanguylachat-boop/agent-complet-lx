# LX Studio - n8n Automation Pipeline

## Guide d'Import et Configuration

Ce guide vous explique comment importer et configurer les workflows n8n pour le pipeline d'automatisation LX Studio.

---

## 📋 Prérequis

- n8n version >= 1.50 (cloud ou self-hosted)
- Compte Supabase (ou PostgreSQL)
- Comptes API : Stripe, Google Workspace, Notion, Typeform
- (Optionnel) Telegram, VAPI/Twilio, Hunter.io

---

## 🚀 Installation - 5 Étapes

### 1️⃣ Créer la Base de Données

```bash
# Connectez-vous à votre instance Supabase/Postgres
psql -h db.xxxxx.supabase.co -U postgres -d postgres

# Exécutez le script de création des tables
\i docs/data-model.sql
```

Vérifiez que toutes les tables ont été créées :
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

---

### 2️⃣ Configurer les Variables d'Environnement

Dans n8n, allez dans **Settings → Environments** et ajoutez toutes les variables du fichier `docs/ENV.example`.

**Méthode alternative (self-hosted)** :
```bash
cp docs/ENV.example .env
# Éditez .env avec vos vraies valeurs
nano .env
```

Puis redémarrez n8n :
```bash
docker-compose restart n8n
# ou
systemctl restart n8n
```

---

### 3️⃣ Créer les Credentials dans n8n

Allez dans **Settings → Credentials** et créez les credentials suivantes :

| Nom du Credential | Type | Configuration |
|-------------------|------|---------------|
| `Supabase Service Role` | HTTP Header Auth | Header: `apikey`, Value: `{{$env.SUPABASE_SERVICE_KEY}}` |
| `Stripe API` | Stripe API | Secret Key: `{{$env.STRIPE_SECRET_KEY}}` |
| `Gmail SMTP` | SMTP | Host: `{{$env.SMTP_HOST}}`, User: `{{$env.SMTP_USER}}`, Pass: `{{$env.SMTP_PASS}}` |
| `Google OAuth2` | Google OAuth2 API | Client ID/Secret (voir ENV) |
| `Notion API` | Notion API | API Key: `{{$env.NOTION_TOKEN}}` |
| `Typeform OAuth2` | Typeform OAuth2 API | OAuth flow |
| `Telegram Bot` | Telegram | Bot Token: `{{$env.TELEGRAM_BOT_TOKEN}}` |
| `OpenAI API` | OpenAI API | API Key: `{{$env.OPENAI_API_KEY}}` |
| `Anthropic API` | HTTP Header Auth | Header: `x-api-key`, Value: `{{$env.ANTHROPIC_API_KEY}}` |
| `Hunter.io API` | HTTP Header Auth | Header: `x-api-key`, Value: `{{$env.HUNTER_API_KEY}}` |
| `VAPI API` | HTTP Header Auth | Header: `Authorization`, Value: `Bearer {{$env.VAPI_API_KEY}}` |

**Important** : Utilisez `{{$env.VARIABLE_NAME}}` pour référencer les variables d'environnement dans les credentials.

---

### 4️⃣ Importer les Workflows

**Ordre d'import important** (commencez par les utilitaires) :

1. **wf-00-shared-utils.json** (workflows utilitaires)
2. wf-01-prospection-enrichissement.json
3. wf-02-contact-audit-express.json
4. wf-03-audit-structuration.json
5. wf-04-cdc-estimation-roi-proposition.json
6. wf-05-closing-assist.json
7. wf-06-paiements-contrat.json
8. wf-07-onboarding-espace-projet.json
9. wf-08-developpement-integration.json
10. wf-09-recette-go-live-formation.json
11. wf-10-run-maintenance-reports.json

**Procédure d'import** :
1. Dans n8n, cliquez sur **Workflows** → **Import from File**
2. Sélectionnez le fichier `.json`
3. Assignez les credentials aux nœuds qui en ont besoin
4. **Activez** le workflow (toggle en haut à droite)

---

### 5️⃣ Tester les Workflows

Utilisez le fichier `docs/test-payloads.http` avec l'extension REST Client de VS Code ou Postman.

**Ordre de tests recommandé** :

```bash
# 1. Test des utilitaires
POST {{BASE_DOMAIN}}/webhook/utils-log
POST {{BASE_DOMAIN}}/webhook/utils-idempotency-check

# 2. Test prospection
POST {{BASE_DOMAIN}}/webhook/prospect-sync

# 3. Simuler un audit
POST {{BASE_DOMAIN}}/webhook/typeform-audit
# (payload exemple dans test-payloads.http)

# 4. Vérifier les logs dans Supabase
SELECT * FROM execution_logs ORDER BY created_at DESC LIMIT 20;
```

---

## 🔐 Configuration Sécurité

### Rotation des Secrets

**À faire tous les 90 jours** :
- Régénérer les API keys (Stripe, Supabase, OpenAI)
- Mettre à jour les credentials dans n8n
- Tester tous les workflows critiques

### Webhooks Stripe

1. Dans le dashboard Stripe, allez dans **Developers → Webhooks**
2. Créez un endpoint : `https://automations.lxstudio.ch/webhook/stripe-payment`
3. Sélectionnez les événements :
   - `payment_intent.succeeded`
   - `payment_intent.failed`
   - `invoice.payment_failed`
4. Copiez le **Signing Secret** dans `STRIPE_WEBHOOK_SECRET`

### Webhooks Typeform

1. Dans chaque formulaire Typeform, allez dans **Connect → Webhooks**
2. URL : `https://automations.lxstudio.ch/webhook/typeform-audit`
3. Activez le webhook

---

## 📊 Configuration Observabilité

### Purge Automatique des Logs

Créez un cron job PostgreSQL (ou workflow n8n mensuel) :

```sql
-- Supprimer les logs > 90 jours
DELETE FROM execution_logs WHERE created_at < now() - interval '90 days';

-- Supprimer les clés d'idempotence > 180 jours
DELETE FROM idempotency_keys WHERE created_at < now() - interval '180 days';
```

### Dashboard de Monitoring (optionnel)

Créez une Google Sheet connectée à Supabase via n8n pour suivre :
- Nombre de prospects par semaine
- Taux de conversion par étape
- MRR (revenus récurrents)
- Temps moyen de closing

Un workflow `wf-11-dashboard-sync.json` peut être ajouté pour mettre à jour cette sheet quotidiennement.

---

## 🎨 Modèles Google Docs

Créez les modèles suivants dans Google Drive :

### Modèle "Audit Client"
```
# Audit d'Automatisation - {{company.name}}
Date : {{audit.date}}

## Contexte
{{audit.context}}

## Processus Manuels Identifiés
{{#audit.manual_tasks}}
- {{task.name}} ({{task.hours_per_week}}h/semaine)
{{/audit.manual_tasks}}

## Opportunités d'Automatisation
{{audit.opportunities}}

## Recommandations
{{audit.recommendations}}
```

### Modèle "Proposition Commerciale"
```
# Proposition d'Automatisation - {{company.name}}
Date : {{proposal.date}}

## Périmètre
{{spec.cdc_summary}}

## Estimation
- Durée : {{estimate.total_hours}} heures
- Coût : {{estimate.total_cost_chf}} CHF
- ROI : {{estimate.roi_percent}}% sur 12 mois
- Payback : {{estimate.payback_months}} mois

## Planning
- Phase 1 : {{timeline.phase1}}
- Phase 2 : {{timeline.phase2}}
- Go-Live : {{timeline.golive}}

## Conditions
- Acompte 30% : {{payment.deposit}} CHF
- Solde 70% : {{payment.balance}} CHF
```

Copiez les IDs de ces documents dans :
- `GOOGLE_TEMPLATE_AUDIT`
- `GOOGLE_TEMPLATE_PROPOSAL`
- `GOOGLE_TEMPLATE_CONTRACT`

---

## 🐛 Troubleshooting

### Problème : "Credential not found"
**Solution** : Vérifiez que le nom du credential dans le nœud correspond EXACTEMENT au nom créé dans Settings → Credentials.

### Problème : "Unauthorized" sur Supabase
**Solution** : Vérifiez que vous utilisez le **Service Role Key** (pas l'Anon Key) dans `SUPABASE_SERVICE_KEY`.

### Problème : Webhooks ne se déclenchent pas
**Solution** :
1. Vérifiez que le workflow est **activé** (toggle vert)
2. Testez l'URL du webhook manuellement (voir test-payloads.http)
3. Vérifiez les logs n8n : **Executions** → filtrer par workflow

### Problème : Rate limit dépassé
**Solution** : Ajustez les variables `RATE_LIMIT_*` dans ENV et ajoutez des nœuds **Wait** entre les requêtes.

### Problème : AI timeout
**Solution** :
- Augmentez le timeout du nœud HTTP (Settings → Timeout à 60000ms)
- Réduisez la taille des prompts
- Utilisez un modèle plus rapide (gpt-3.5-turbo au lieu de gpt-4)

---

## 📈 Optimisations Post-Installation

### Activer les Queues (n8n self-hosted)

Pour gérer les pics de charge :
```yaml
# docker-compose.yml
environment:
  - QUEUE_BULL_REDIS_HOST=redis
  - EXECUTIONS_MODE=queue
```

### Monitoring Externe

Ajoutez Sentry pour les erreurs :
```javascript
// Dans les nœuds Function
if (error) {
  Sentry.captureException(error, {
    tags: { workflow: 'wf-01-prospection' }
  });
}
```

### Backup Automatique

Créez un workflow n8n quotidien qui exporte :
1. Tous les workflows actifs (API n8n)
2. Un dump Postgres des tables critiques
3. Upload vers Google Drive

---

## 📚 Ressources

- [Documentation n8n](https://docs.n8n.io)
- [Supabase Docs](https://supabase.com/docs)
- [Stripe API](https://stripe.com/docs/api)
- [Typeform API](https://developer.typeform.com)

---

## ✅ Checklist Post-Installation

- [ ] Base de données créée et testée
- [ ] Toutes les variables ENV configurées
- [ ] Tous les credentials créés dans n8n
- [ ] 11 workflows importés et activés
- [ ] Webhooks Stripe configurés
- [ ] Webhooks Typeform configurés
- [ ] Modèles Google Docs créés
- [ ] Tests de bout en bout passés
- [ ] Monitoring et alertes actifs
- [ ] Backup configuré
- [ ] Documentation partagée avec l'équipe

---

**Support** : Pour toute question, créez une issue sur le repo GitHub ou contactez tech@lxstudio.ch
