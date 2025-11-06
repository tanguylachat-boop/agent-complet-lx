# Logging Schema - LX Studio Automation Pipeline

## Vue d'ensemble

Tous les workflows n8n écrivent des logs structurés dans la table `execution_logs` pour permettre l'observabilité, le debugging et l'audit.

---

## Structure d'un Log

### Schéma SQL

```sql
CREATE TABLE execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow TEXT NOT NULL,       -- nom du workflow (wf-01-prospection...)
  run_id TEXT,                   -- n8n execution ID
  step TEXT,                     -- nom de l'étape (ex: "Fetch Companies")
  level TEXT NOT NULL,           -- info|warn|error
  message TEXT NOT NULL,         -- message lisible
  payload JSONB,                 -- données structurées (limitées à 4KB)
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Champs Obligatoires

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `workflow` | TEXT | Identifiant du workflow | `wf-01-prospection` |
| `level` | TEXT | Niveau de log | `info`, `warn`, `error` |
| `message` | TEXT | Message lisible pour les humains | `Successfully fetched 25 companies` |

### Champs Optionnels

| Champ | Type | Description | Exemple |
|-------|------|-------------|---------|
| `run_id` | TEXT | ID d'exécution n8n (pour tracer toute l'exécution) | `12345-abcde-67890` |
| `step` | TEXT | Nom du nœud/étape en cours | `01 Fetch Companies` |
| `payload` | JSONB | Données structurées pertinentes | `{"count": 25, "source": "google_places"}` |

---

## Niveaux de Log

### INFO
- Opérations normales réussies
- Début/fin d'un workflow
- Métriques (nb de records traités, durée)

**Exemples** :
```
✅ Workflow started
✅ Fetched 42 companies from Google Places
✅ Sent 3 emails successfully
✅ Workflow completed in 12.4s
```

### WARN
- Situations inhabituelles mais non bloquantes
- Rate limits approchés
- Données manquantes mais avec fallback
- Retries réussis

**Exemples** :
```
⚠️ No email found for company, skipping enrichment
⚠️ Rate limit reached, waiting 5s before retry
⚠️ Missing field 'phone', using default value
⚠️ Retry 2/3 for HTTP request
```

### ERROR
- Échecs bloquants
- Exceptions non gérées
- Données corrompues
- Intégrations tierces indisponibles

**Exemples** :
```
❌ Failed to insert into Supabase: Connection timeout
❌ Stripe API returned 500
❌ Invalid JSON in Typeform response
❌ AI request timed out after 60s
```

---

## Format JSON du Payload

### Règles
1. **Taille limitée** : max 4KB (tronquer si nécessaire)
2. **Pas de secrets** : masquer API keys, tokens, passwords
3. **Données utiles** : IDs, counts, statuts, erreurs
4. **Pas de duplication** : ne pas répéter le message

### Exemple de Payload INFO

```json
{
  "action": "fetch_companies",
  "source": "google_places",
  "query": "PME Jura Suisse",
  "results_count": 25,
  "inserted": 18,
  "updated": 7,
  "duration_ms": 1420
}
```

### Exemple de Payload WARN

```json
{
  "issue": "missing_field",
  "field": "email",
  "company_id": "123e4567-e89b-12d3-a456-426614174000",
  "fallback_action": "skip_enrichment"
}
```

### Exemple de Payload ERROR

```json
{
  "error": "HTTP Request failed",
  "status_code": 500,
  "endpoint": "https://api.stripe.com/v1/payment_intents",
  "retry_count": 3,
  "last_error_message": "Internal Server Error",
  "context": {
    "company_id": "123e4567-e89b-12d3-a456-426614174000",
    "amount_chf": 4500
  }
}
```

---

## Masquage des Données Sensibles

### Fonction de Masquage (n8n Function Node)

```javascript
// Fonction réutilisable pour masquer les données sensibles

function maskSensitiveData(obj) {
  const sensitiveKeys = [
    'password', 'token', 'api_key', 'secret', 'apikey',
    'authorization', 'credit_card', 'ssn', 'stripe_key'
  ];

  const masked = JSON.parse(JSON.stringify(obj)); // deep clone

  function recurse(o) {
    for (let key in o) {
      if (typeof o[key] === 'object' && o[key] !== null) {
        recurse(o[key]);
      } else if (sensitiveKeys.some(sk => key.toLowerCase().includes(sk))) {
        o[key] = '***MASKED***';
      }
    }
  }

  recurse(masked);
  return masked;
}

// Utilisation
const payload = {
  company_id: '12345',
  stripe_api_key: 'sk_live_xxxxx',  // sera masqué
  email: 'contact@example.com'
};

const safe_payload = maskSensitiveData(payload);
// => { company_id: '12345', stripe_api_key: '***MASKED***', email: 'contact@example.com' }
```

### Limitation de Taille (4KB max)

```javascript
function truncatePayload(payload, maxBytes = 4096) {
  let json = JSON.stringify(payload);

  if (Buffer.byteLength(json, 'utf8') <= maxBytes) {
    return payload;
  }

  // Tronquer et ajouter un indicateur
  const truncated = json.substring(0, maxBytes - 100);
  return JSON.parse(truncated + '... [TRUNCATED]"}');
}
```

---

## Workflow Utils : Log Writer

### Nœud Réutilisable (wf-00-shared-utils / utils-log)

**Input attendu** :
```json
{
  "workflow": "wf-01-prospection",
  "run_id": "{{$execution.id}}",
  "step": "01 Fetch Companies",
  "level": "info",
  "message": "Successfully fetched 25 companies",
  "payload": {
    "count": 25,
    "source": "google_places"
  }
}
```

**Implémentation** :
1. Nœud Function : masquer données sensibles + tronquer
2. Nœud HTTP Request (Supabase) : INSERT dans `execution_logs`

### Appel depuis un Workflow

```javascript
// Dans n8n, nœud "Execute Workflow"
// Workflow: wf-00-shared-utils / utils-log

return [{
  json: {
    workflow: 'wf-01-prospection',
    run_id: $execution.id,
    step: $node.name,
    level: 'info',
    message: `Fetched ${items.length} companies`,
    payload: {
      count: items.length,
      source: 'google_places'
    }
  }
}];
```

---

## Requêtes d'Analyse

### Logs des dernières 24h par niveau

```sql
SELECT
  level,
  COUNT(*) as count,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percent
FROM execution_logs
WHERE created_at > now() - interval '24 hours'
GROUP BY level
ORDER BY count DESC;
```

### Workflows les plus actifs

```sql
SELECT
  workflow,
  COUNT(*) as executions,
  COUNT(CASE WHEN level = 'error' THEN 1 END) as errors,
  ROUND(COUNT(CASE WHEN level = 'error' THEN 1 END) * 100.0 / COUNT(*), 2) as error_rate
FROM execution_logs
WHERE created_at > now() - interval '7 days'
GROUP BY workflow
ORDER BY executions DESC;
```

### Erreurs récentes avec contexte

```sql
SELECT
  created_at,
  workflow,
  step,
  message,
  payload->>'error' as error_detail,
  payload->>'context' as context
FROM execution_logs
WHERE level = 'error'
ORDER BY created_at DESC
LIMIT 50;
```

### Durée moyenne par workflow (si stockée dans payload)

```sql
SELECT
  workflow,
  COUNT(*) as runs,
  ROUND(AVG((payload->>'duration_ms')::numeric), 2) as avg_duration_ms,
  MAX((payload->>'duration_ms')::numeric) as max_duration_ms
FROM execution_logs
WHERE payload->>'duration_ms' IS NOT NULL
GROUP BY workflow
ORDER BY avg_duration_ms DESC;
```

---

## Alerting & Monitoring

### Alertes Telegram pour Erreurs Critiques

Configuration dans `wf-00-shared-utils / utils-error-handler` :

```javascript
// Déclencher une alerte Telegram si erreur critique

const error = $input.item.json;

const shouldAlert = (
  error.level === 'error' &&
  (
    error.workflow.includes('paiements') ||  // Payments = critical
    error.workflow.includes('contrat') ||
    error.payload?.status_code >= 500 ||     // Server errors
    error.payload?.retry_count >= 3          // Max retries reached
  )
);

if (shouldAlert) {
  // Appeler le workflow utils-notify-telegram
  return [{ json: error }];
} else {
  // Log seulement, pas d'alerte
  return [];
}
```

### Dashboard Google Sheets (optionnel)

Créer un workflow quotidien qui agrège les logs et met à jour une Google Sheet :

| Workflow | Executions (7j) | Erreurs | Taux d'Erreur | Dernière Exec |
|----------|-----------------|---------|---------------|---------------|
| wf-01-prospection | 42 | 2 | 4.8% | 2025-01-15 10:30 |
| wf-02-contact | 38 | 0 | 0% | 2025-01-15 09:15 |
| ... | ... | ... | ... | ... |

---

## Exemples de Logs par Workflow

### wf-01-prospection-enrichissement.json

```sql
-- Workflow started
{ "workflow": "wf-01-prospection", "level": "info", "message": "Workflow started", "payload": {"trigger": "cron"} }

-- Fetching companies
{ "workflow": "wf-01-prospection", "level": "info", "step": "01 Fetch Google Places", "message": "Fetching companies from Google Places", "payload": {"query": "PME Jura", "limit": 50} }

-- Results
{ "workflow": "wf-01-prospection", "level": "info", "step": "02 Normalize", "message": "Normalized 42 companies", "payload": {"count": 42, "duplicates_removed": 8} }

-- Upsert
{ "workflow": "wf-01-prospection", "level": "info", "step": "03 Upsert Supabase", "message": "Upserted 34 companies", "payload": {"inserted": 27, "updated": 7} }

-- Completion
{ "workflow": "wf-01-prospection", "level": "info", "message": "Workflow completed", "payload": {"total_processed": 34, "duration_ms": 8420} }
```

### wf-06-paiements-contrat.json (avec erreur)

```sql
-- Workflow started
{ "workflow": "wf-06-paiements", "level": "info", "message": "Workflow started", "payload": {"company_id": "123e4567..."} }

-- Stripe payment intent creation
{ "workflow": "wf-06-paiements", "level": "info", "step": "01 Create Stripe Payment Intent", "message": "Creating payment intent", "payload": {"amount_chf": 4500, "type": "deposit"} }

-- ERROR!
{ "workflow": "wf-06-paiements", "level": "error", "step": "01 Create Stripe Payment Intent", "message": "Stripe API error", "payload": {"status_code": 402, "error": "card_declined", "retry_count": 0} }

-- Retry
{ "workflow": "wf-06-paiements", "level": "warn", "step": "01 Create Stripe Payment Intent", "message": "Retrying Stripe request (1/3)", "payload": {} }

-- Success after retry
{ "workflow": "wf-06-paiements", "level": "info", "step": "01 Create Stripe Payment Intent", "message": "Payment intent created", "payload": {"payment_intent_id": "pi_xxxxx", "retry_count": 1} }
```

---

## Bonnes Pratiques

### ✅ À FAIRE

1. **Logger au début et à la fin** de chaque workflow
2. **Logger les métriques** (nb records, durée)
3. **Logger avant/après les appels API** externes
4. **Masquer les secrets** avant d'écrire le payload
5. **Utiliser des messages lisibles** (pas de codes cryptiques)
6. **Inclure le run_id** pour tracer une exécution complète

### ❌ À ÉVITER

1. ❌ Logger des secrets (API keys, tokens, passwords)
2. ❌ Logger des payloads > 4KB (tronquer !)
3. ❌ Logger à chaque itération d'une boucle (agréger)
4. ❌ Dupliquer des infos déjà dans d'autres champs
5. ❌ Utiliser des niveaux incorrects (ex: `error` pour un warning)

---

## Retention & Purge

### Stratégie de Rétention

| Niveau | Durée de Rétention | Méthode |
|--------|---------------------|---------|
| `info` | 90 jours | Purge auto (cron) |
| `warn` | 180 jours | Purge auto (cron) |
| `error` | 365 jours | Purge manuelle après investigation |

### Script de Purge (Cron ou n8n mensuel)

```sql
-- Purger les logs INFO > 90 jours
DELETE FROM execution_logs
WHERE level = 'info'
  AND created_at < now() - interval '90 days';

-- Purger les logs WARN > 180 jours
DELETE FROM execution_logs
WHERE level = 'warn'
  AND created_at < now() - interval '180 days';

-- Archive des erreurs (optionnel)
-- Copier vers une table d'archive avant de purger
INSERT INTO execution_logs_archive
SELECT * FROM execution_logs
WHERE level = 'error'
  AND created_at < now() - interval '365 days';

DELETE FROM execution_logs
WHERE level = 'error'
  AND created_at < now() - interval '365 days';
```

---

## Export & Analyse Externe

### Export vers Datadog/Sentry

```javascript
// Nœud Function : Send to Datadog

const log = $input.item.json;

if (log.level === 'error') {
  // Datadog Logs API
  await $http.post('https://http-intake.logs.datadoghq.com/api/v2/logs', {
    headers: {
      'DD-API-KEY': $env.DATADOG_API_KEY
    },
    body: {
      ddsource: 'n8n',
      ddtags: `workflow:${log.workflow},env:production`,
      hostname: 'n8n-lxstudio',
      message: log.message,
      level: log.level,
      ...log.payload
    }
  });
}

return { json: log };
```

---

**Voir aussi** :
- [README-import.md](./README-import.md) pour la configuration
- [test-payloads.http](./test-payloads.http) pour tester les workflows
