# Typeform → JSON Mapping

## Vue d'ensemble

Ce document décrit comment les réponses Typeform sont mappées vers notre modèle de données JSON pour être traitées par les workflows n8n.

---

## Formulaire Audit Initial

**Typeform ID** : `{{TYPEFORM_AUDIT_ID}}`
**Webhook URL** : `{{BASE_DOMAIN}}/webhook/typeform-audit`

### Questions → Champs JSON

| Question Typeform | Field ID | Type | Mapping JSON |
|-------------------|----------|------|--------------|
| Nom de l'entreprise | `field_company_name` | short_text | `company.name` |
| Site web | `field_website` | website | `company.website` |
| Email de contact | `field_email` | email | `contact.email` |
| Téléphone | `field_phone` | phone_number | `contact.phone` |
| Industrie/secteur | `field_industry` | dropdown | `company.industry` |
| Nombre d'employés | `field_size` | multiple_choice | `company.size_employees` |
| Quel est votre principal défi business aujourd'hui ? | `field_challenge` | long_text | `audit.pain_points[0]` |
| Quels processus sont actuellement manuels ? | `field_manual_processes` | multiple_choice | `audit.manual_tasks` |
| Combien d'heures par semaine sont consacrées à ces tâches ? | `field_hours_manual` | number | `audit.manual_hours_per_week` |
| Utilisez-vous déjà des outils d'automatisation ? | `field_current_tools` | yes_no + text | `audit.structured_data.current_tools` |
| Budget approximatif pour l'automatisation | `field_budget` | opinion_scale | `audit.structured_data.budget_range` |
| Objectif principal de l'automatisation | `field_goal` | dropdown | `audit.structured_data.primary_goal` |
| Timeline souhaitée | `field_timeline` | dropdown | `audit.structured_data.desired_timeline` |
| Commentaires libres | `field_comments` | long_text | `audit.structured_data.additional_notes` |

### Exemple de Payload Webhook Typeform

```json
{
  "event_id": "01HXXX123456789",
  "event_type": "form_response",
  "form_response": {
    "form_id": "XxXxXxXx",
    "token": "xxx123456789",
    "landed_at": "2025-01-15T10:30:00Z",
    "submitted_at": "2025-01-15T10:35:42Z",
    "hidden": {
      "source": "linkedin_ad",
      "utm_campaign": "swiss_pme_q1"
    },
    "definition": {
      "id": "XxXxXxXx",
      "title": "Audit d'Automatisation - LX Studio",
      "fields": [...]
    },
    "answers": [
      {
        "type": "text",
        "text": "Café du Jura SA",
        "field": {
          "id": "field_company_name",
          "type": "short_text",
          "ref": "company_name"
        }
      },
      {
        "type": "url",
        "url": "https://cafedujura.ch",
        "field": {
          "id": "field_website",
          "type": "website",
          "ref": "website"
        }
      },
      {
        "type": "email",
        "email": "jean.dupont@cafedujura.ch",
        "field": {
          "id": "field_email",
          "type": "email",
          "ref": "email"
        }
      },
      {
        "type": "phone_number",
        "phone_number": "+41 32 123 45 67",
        "field": {
          "id": "field_phone",
          "type": "phone_number",
          "ref": "phone"
        }
      },
      {
        "type": "choice",
        "choice": {
          "label": "Hôtellerie/Restauration"
        },
        "field": {
          "id": "field_industry",
          "type": "dropdown",
          "ref": "industry"
        }
      },
      {
        "type": "choice",
        "choice": {
          "label": "10-50 employés"
        },
        "field": {
          "id": "field_size",
          "type": "multiple_choice",
          "ref": "size"
        }
      },
      {
        "type": "text",
        "text": "Nous perdons beaucoup de temps à gérer manuellement les commandes et la facturation. Les erreurs sont fréquentes et nous aimerions fluidifier le processus de la commande au paiement.",
        "field": {
          "id": "field_challenge",
          "type": "long_text",
          "ref": "challenge"
        }
      },
      {
        "type": "choices",
        "choices": {
          "labels": [
            "Saisie de commandes",
            "Facturation",
            "Suivi des stocks",
            "Relances clients"
          ]
        },
        "field": {
          "id": "field_manual_processes",
          "type": "multiple_choice",
          "ref": "manual_processes"
        }
      },
      {
        "type": "number",
        "number": 15,
        "field": {
          "id": "field_hours_manual",
          "type": "number",
          "ref": "hours_manual"
        }
      },
      {
        "type": "boolean",
        "boolean": false,
        "field": {
          "id": "field_current_tools",
          "type": "yes_no",
          "ref": "current_tools"
        }
      },
      {
        "type": "number",
        "number": 7,
        "field": {
          "id": "field_budget",
          "type": "opinion_scale",
          "ref": "budget"
        }
      },
      {
        "type": "choice",
        "choice": {
          "label": "Gagner du temps sur les tâches répétitives"
        },
        "field": {
          "id": "field_goal",
          "type": "dropdown",
          "ref": "goal"
        }
      },
      {
        "type": "choice",
        "choice": {
          "label": "1-3 mois"
        },
        "field": {
          "id": "field_timeline",
          "type": "dropdown",
          "ref": "timeline"
        }
      },
      {
        "type": "text",
        "text": "Nous sommes ouverts à discuter et voir ce qui est possible.",
        "field": {
          "id": "field_comments",
          "type": "long_text",
          "ref": "comments"
        }
      }
    ]
  }
}
```

### Transformation JSON (dans n8n Function Node)

```javascript
// Node: Transform Typeform to Audit JSON

const answers = $input.item.json.form_response.answers;

// Helper function to find answer by field ref
function getAnswer(ref, defaultValue = null) {
  const answer = answers.find(a => a.field.ref === ref);
  if (!answer) return defaultValue;

  if (answer.type === 'text') return answer.text;
  if (answer.type === 'email') return answer.email;
  if (answer.type === 'url') return answer.url;
  if (answer.type === 'phone_number') return answer.phone_number;
  if (answer.type === 'number') return answer.number;
  if (answer.type === 'boolean') return answer.boolean;
  if (answer.type === 'choice') return answer.choice.label;
  if (answer.type === 'choices') return answer.choices.labels;

  return defaultValue;
}

// Build normalized JSON
const normalized = {
  source: 'typeform',
  form_id: $input.item.json.form_response.form_id,
  submitted_at: $input.item.json.form_response.submitted_at,
  company: {
    name: getAnswer('company_name'),
    website: getAnswer('website'),
    industry: getAnswer('industry'),
    size_employees: getAnswer('size')
  },
  contact: {
    email: getAnswer('email'),
    phone: getAnswer('phone')
  },
  audit: {
    pain_points: [getAnswer('challenge')],
    manual_tasks: getAnswer('manual_processes', []),
    manual_hours_per_week: getAnswer('hours_manual', 0),
    structured_data: {
      current_tools: getAnswer('current_tools', false),
      budget_range: getAnswer('budget'),
      primary_goal: getAnswer('goal'),
      desired_timeline: getAnswer('timeline'),
      additional_notes: getAnswer('comments')
    }
  },
  raw_responses: $input.item.json.form_response
};

return { json: normalized };
```

---

## Formulaire Onboarding

**Typeform ID** : `{{TYPEFORM_ONBOARDING_ID}}`
**Webhook URL** : `{{BASE_DOMAIN}}/webhook/onboarding-completed`

### Questions → Champs JSON

| Question | Field Ref | Mapping JSON |
|----------|-----------|--------------|
| Qui sera le référent technique ? | `tech_contact` | `project.tech_contact_name` |
| Email du référent | `tech_email` | `project.tech_contact_email` |
| Accès aux systèmes (API keys, logins) | `access_details` | `project.access_credentials` |
| Volumes de données quotidiens | `data_volumes` | `project.daily_volumes` |
| Contraintes de timing (heures d'exécution) | `timing_constraints` | `project.execution_constraints` |
| Environnements (prod, staging) | `environments` | `project.environments` |

---

## Formulaire UAT (Recette)

**Typeform ID** : `{{TYPEFORM_UAT_ID}}`
**Webhook URL** : `{{BASE_DOMAIN}}/webhook/uat-checklist`

### Questions → Champs JSON

| Question | Field Ref | Mapping JSON |
|----------|-----------|--------------|
| Tous les flows fonctionnent ? | `flows_working` | `uat.flows_status` |
| Erreurs rencontrées ? | `errors_found` | `uat.errors` |
| Performance acceptable ? | `performance_ok` | `uat.performance_ok` |
| Documentation claire ? | `docs_clear` | `uat.docs_feedback` |
| Prêt pour le Go-Live ? | `ready_golive` | `uat.go_live_ready` |

---

## Formulaire NPS (Satisfaction)

**Typeform ID** : `{{TYPEFORM_NPS_ID}}`
**Webhook URL** : `{{BASE_DOMAIN}}/webhook/nps-response`

### Questions → Champs JSON

| Question | Field Ref | Mapping JSON |
|----------|-----------|--------------|
| Sur une échelle de 0-10, recommanderiez-vous LX Studio ? | `nps_score` | `nps.score` |
| Pourquoi cette note ? | `nps_reason` | `nps.feedback` |
| Que pourrions-nous améliorer ? | `nps_improvements` | `nps.improvements_suggested` |

---

## Configuration des Webhooks dans Typeform

1. Dans le builder Typeform, onglet **Connect**
2. Cliquez sur **Webhooks**
3. Activez le toggle
4. URL : `https://automations.lxstudio.ch/webhook/{endpoint}`
5. **Secret** : optionnel (pour vérifier la signature)

### Vérification de Signature (optionnel)

```javascript
// Dans le workflow n8n, nœud Function avant le traitement

const crypto = require('crypto');

const signature = $input.item.headers['typeform-signature'];
const body = JSON.stringify($input.item.json);
const secret = $env.TYPEFORM_WEBHOOK_SECRET;

const hash = crypto
  .createHmac('sha256', secret)
  .update(body)
  .digest('base64');

const expectedSignature = `sha256=${hash}`;

if (signature !== expectedSignature) {
  throw new Error('Invalid Typeform signature');
}

return { json: $input.item.json };
```

---

## Mapping Reverse : JSON → Typeform (pré-remplissage)

Pour créer des liens Typeform pré-remplis :

```javascript
// Générer un lien Typeform avec pré-remplissage

const company = $input.item.json;

const params = new URLSearchParams({
  'company_name': company.name,
  'website': company.website || '',
  'email': company.contacts[0]?.email || '',
  'phone': company.phone || '',
  'industry': company.industry || ''
});

const typeformUrl = `https://form.typeform.com/to/${$env.TYPEFORM_ONBOARDING_ID}#${params.toString()}`;

return { json: { typeform_url: typeformUrl } };
```

---

## Budget Range Mapping

Échelle d'opinion Typeform (1-10) → Budget estimé :

| Score | Budget Estimé (CHF) |
|-------|---------------------|
| 1-2   | < 5'000 |
| 3-4   | 5'000 - 10'000 |
| 5-6   | 10'000 - 20'000 |
| 7-8   | 20'000 - 50'000 |
| 9-10  | > 50'000 |

```javascript
// Function Node
const score = $input.item.json.audit.structured_data.budget_range;

let budget_estimate;
if (score <= 2) budget_estimate = "< 5000";
else if (score <= 4) budget_estimate = "5000-10000";
else if (score <= 6) budget_estimate = "10000-20000";
else if (score <= 8) budget_estimate = "20000-50000";
else budget_estimate = "> 50000";

return { json: { ...$$input.item.json, budget_estimate } };
```

---

## Logging des Réponses

Toutes les réponses brutes sont stockées dans `audits.raw_responses` (JSONB) pour traçabilité et debugging.

```sql
-- Exemple de requête pour analyser les réponses
SELECT
  company_id,
  raw_responses->'form_response'->'submitted_at' as submitted_at,
  raw_responses->'form_response'->'answers' as answers
FROM audits
WHERE source = 'typeform'
ORDER BY created_at DESC;
```

---

## Erreurs Courantes

### Champ manquant dans la réponse
**Cause** : Question optionnelle non répondue
**Solution** : Toujours utiliser `defaultValue` dans `getAnswer()`

### Type de réponse inattendu
**Cause** : Typeform a changé le type de question
**Solution** : Vérifier le type avec `answer.type` avant de parser

### Webhook non déclenché
**Cause** : Webhook désactivé ou URL incorrecte
**Solution** : Vérifier dans Typeform Connect → Webhooks → Test webhook

---

**Documentation Typeform** : https://developer.typeform.com/webhooks/
