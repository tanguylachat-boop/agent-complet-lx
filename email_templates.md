# LX Studio - Email Templates

Tous les templates utilisent la syntaxe de placeholders `{{ variable }}` compatible avec n8n.

---

## 1. EMAIL DEVIS (Quote Email)

### Sujet
```
Votre devis LX Studio - {{ project.service_type_label }}
```

### Corps HTML
```html
<!DOCTYPE html>
<html lang="fr-CH">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Devis LX Studio</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #0066cc;
        }
        .logo {
            font-size: 28px;
            font-weight: bold;
            color: #0066cc;
            margin-bottom: 10px;
        }
        .tagline {
            color: #666;
            font-size: 14px;
        }
        h1 {
            color: #0066cc;
            font-size: 24px;
            margin-bottom: 20px;
        }
        .greeting {
            margin-bottom: 20px;
        }
        .amount-box {
            background-color: #f8f9fa;
            border-left: 4px solid #0066cc;
            padding: 20px;
            margin: 30px 0;
            border-radius: 4px;
        }
        .amount-box .label {
            font-size: 14px;
            color: #666;
            margin-bottom: 5px;
        }
        .amount-box .amount {
            font-size: 32px;
            font-weight: bold;
            color: #0066cc;
        }
        .button {
            display: inline-block;
            background-color: #0066cc;
            color: #ffffff !important;
            padding: 14px 28px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            margin: 20px 0;
            text-align: center;
        }
        .button:hover {
            background-color: #0052a3;
        }
        .info-section {
            margin: 25px 0;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            font-size: 13px;
            color: #666;
            text-align: center;
        }
        .contact-info {
            margin-top: 20px;
        }
        .contact-info a {
            color: #0066cc;
            text-decoration: none;
        }
        .attachment-notice {
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            padding: 12px;
            border-radius: 4px;
            margin: 20px 0;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">LX STUDIO</div>
            <div class="tagline">Agence Web & Automatisation | Suisse Romande</div>
        </div>

        <div class="greeting">
            <p>Bonjour {{ contact.first_name }},</p>
        </div>

        <p>
            Merci pour votre demande concernant <strong>{{ project.description_short }}</strong>.
            Nous avons le plaisir de vous transmettre notre proposition détaillée.
        </p>

        <div class="amount-box">
            <div class="label">Montant total TTC</div>
            <div class="amount">{{ pricing.amount_ttc | format_chf }} CHF</div>
            <div class="label" style="margin-top: 10px;">
                (dont {{ pricing.amount_ht | format_chf }} CHF HT + TVA 7.7%)
            </div>
        </div>

        <div class="info-section">
            <h3 style="margin-top: 0; color: #333;">📋 Détails du projet</h3>
            <ul style="margin: 10px 0; padding-left: 20px;">
                <li><strong>Service :</strong> {{ project.service_type_label }}</li>
                <li><strong>Délai estimé :</strong> {{ project.timeline_estimated }}</li>
                <li><strong>Garantie :</strong> {{ project.warranty_period }}</li>
                <li><strong>Support inclus :</strong> {{ project.support_included }}</li>
            </ul>
        </div>

        <div class="attachment-notice">
            📎 Le devis détaillé complet est joint à cet email en PDF.
        </div>

        <div style="text-align: center; margin: 30px 0;">
            <a href="{{ quote.accept_url }}" class="button">
                ✅ Accepter ce devis
            </a>
        </div>

        <p style="font-size: 14px; color: #666;">
            Ce devis est valable jusqu'au <strong>{{ quote.expires_at | format_date }}</strong>.
            En cliquant sur "Accepter ce devis", vous recevrez automatiquement votre facture avec les modalités de paiement.
        </p>

        <div class="info-section" style="background-color: #e8f4fd; border-left: 4px solid #0066cc;">
            <p style="margin: 0;"><strong>💬 Des questions ?</strong></p>
            <p style="margin: 5px 0 0 0; font-size: 14px;">
                Nous sommes à votre disposition pour toute clarification.
                Répondez simplement à cet email ou appelez-nous.
            </p>
        </div>

        <div class="footer">
            <div class="contact-info">
                <strong>LX Studio</strong><br>
                Agence Web & Automatisation<br>
                Email: <a href="mailto:contact@lxstudio.ch">contact@lxstudio.ch</a><br>
                Web: <a href="https://lxstudio.ch">lxstudio.ch</a><br>
                📅 <a href="{{ calendly_link }}">Prendre rendez-vous</a>
            </div>
            <p style="margin-top: 20px; font-size: 12px; color: #999;">
                LX Studio | Suisse Romande<br>
                Vous recevez cet email suite à votre demande de devis.
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 2. EMAIL FACTURE (Invoice Email)

### Sujet
```
Facture LX Studio n°{{ invoice.invoice_number }} - Paiement
```

### Corps HTML
```html
<!DOCTYPE html>
<html lang="fr-CH">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Facture LX Studio</title>
    <style>
        /* Réutiliser les mêmes styles que le template devis */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #28a745;
        }
        .logo {
            font-size: 28px;
            font-weight: bold;
            color: #28a745;
            margin-bottom: 10px;
        }
        .tagline {
            color: #666;
            font-size: 14px;
        }
        .button {
            display: inline-block;
            background-color: #28a745;
            color: #ffffff !important;
            padding: 14px 28px;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 600;
            margin: 20px 0;
            text-align: center;
        }
        .button:hover {
            background-color: #218838;
        }
        .amount-box {
            background-color: #f8f9fa;
            border-left: 4px solid #28a745;
            padding: 20px;
            margin: 30px 0;
            border-radius: 4px;
        }
        .amount-box .label {
            font-size: 14px;
            color: #666;
            margin-bottom: 5px;
        }
        .amount-box .amount {
            font-size: 32px;
            font-weight: bold;
            color: #28a745;
        }
        .info-section {
            margin: 25px 0;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            font-size: 13px;
            color: #666;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">LX STUDIO</div>
            <div class="tagline">Facture n°{{ invoice.invoice_number }}</div>
        </div>

        <p>Bonjour {{ contact.first_name }},</p>

        <p>
            Suite à l'acceptation de votre devis, voici votre facture pour
            <strong>{{ project.description_short }}</strong>.
        </p>

        <div class="amount-box">
            <div class="label">Montant à régler</div>
            <div class="amount">{{ invoice.amount_ttc | format_chf }} CHF</div>
            <div class="label" style="margin-top: 10px;">
                Échéance : <strong>{{ invoice.due_date | format_date }}</strong>
            </div>
        </div>

        <div style="text-align: center; margin: 30px 0;">
            <a href="{{ invoice.payment_url }}" class="button">
                💳 Procéder au paiement
            </a>
        </div>

        <div class="info-section">
            <h3 style="margin-top: 0;">Moyens de paiement</h3>
            <ul style="margin: 10px 0; padding-left: 20px;">
                <li>💳 Carte bancaire (paiement sécurisé via Stripe)</li>
                <li>🏦 Virement bancaire (coordonnées sur la facture PDF)</li>
                <li>📱 TWINT (sur demande)</li>
            </ul>
        </div>

        <div class="info-section" style="background-color: #e7f5ff;">
            <p style="margin: 0;"><strong>📅 Prochaines étapes</strong></p>
            <p style="margin: 10px 0 0 0; font-size: 14px;">
                Dès réception de votre paiement, nous vous contacterons pour planifier
                le lancement du projet. Délai de réalisation estimé : <strong>{{ project.timeline_estimated }}</strong>.
            </p>
        </div>

        <p style="font-size: 14px; color: #666; margin-top: 30px;">
            Merci de votre confiance ! Nous sommes impatients de collaborer avec vous.
        </p>

        <div class="footer">
            <strong>LX Studio</strong><br>
            Email: <a href="mailto:contact@lxstudio.ch" style="color: #28a745;">contact@lxstudio.ch</a><br>
            Web: <a href="https://lxstudio.ch" style="color: #28a745;">lxstudio.ch</a>
            <p style="margin-top: 15px; font-size: 12px; color: #999;">
                Facture générée automatiquement | LX Studio, Suisse Romande
            </p>
        </div>
    </div>
</body>
</html>
```

---

## 3. EMAIL RÉCAPITULATIF APPEL (Voice Call Summary)

### Sujet
```
Récapitulatif de votre appel - LX Studio
```

### Corps HTML
```html
<!DOCTYPE html>
<html lang="fr-CH">
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .container {
            background-color: #ffffff;
            padding: 30px;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
        }
        .header {
            border-bottom: 2px solid #6c63ff;
            padding-bottom: 15px;
            margin-bottom: 25px;
        }
        .summary-box {
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 4px;
            margin: 20px 0;
        }
        .button {
            display: inline-block;
            background-color: #6c63ff;
            color: #ffffff !important;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2 style="margin: 0; color: #6c63ff;">📞 Récapitulatif de votre appel</h2>
        </div>

        <p>Bonjour {{ contact.first_name || 'Madame, Monsieur' }},</p>

        <p>
            Merci pour votre appel. Voici un récapitulatif de notre échange :
        </p>

        <div class="summary-box">
            <p><strong>Date & Heure :</strong> {{ call.created_at | format_datetime }}</p>
            <p><strong>Durée :</strong> {{ call.duration }} secondes</p>
            <p><strong>Résumé :</strong></p>
            <p style="margin-left: 15px; font-style: italic;">
                {{ call.summary }}
            </p>
        </div>

        <p>
            Nous avons bien noté votre demande et reviendrons vers vous dans les plus brefs délais.
        </p>

        <div style="text-align: center; margin: 25px 0;">
            <a href="{{ calendly_link }}" class="button">
                📅 Planifier un rendez-vous
            </a>
        </div>

        <p style="font-size: 13px; color: #666; margin-top: 30px;">
            Si vous avez des questions, n'hésitez pas à nous contacter à
            <a href="mailto:contact@lxstudio.ch">contact@lxstudio.ch</a>.
        </p>

        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0; text-align: center; font-size: 12px; color: #999;">
            LX Studio | Agence Web & Automatisation<br>
            Suisse Romande | <a href="https://lxstudio.ch">lxstudio.ch</a>
        </div>
    </div>
</body>
</html>
```

---

## 4. EMAIL NOTIFICATION INTERNE (Error Alert)

### Sujet
```
🚨 Erreur Workflow: {{ workflow_name }} | {{ error.severity }}
```

### Corps (texte simple pour notifications internes)
```
⚠️ ERREUR WORKFLOW N8N

Workflow: {{ workflow_name }}
Node: {{ node_name }}
Execution ID: {{ execution_id }}
Sévérité: {{ error.severity }}
Date: {{ error.created_at | format_datetime }}

MESSAGE D'ERREUR:
{{ error.error_message }}

DONNÉES D'ENTRÉE:
{{ error.input_data | json_pretty }}

STACK TRACE:
{{ error.stack_trace }}

---
Consulter l'exécution: {{ base_url_n8n }}/workflow/{{ workflow_id }}/executions/{{ execution_id }}

Logs Supabase: https://app.supabase.com/project/{{ supabase_project }}/editor/{{ errors_table }}
```

---

## 5. EMAIL PROSPECTION (Variable selon personnalisation LLM)

### Sujet (généré par LLM)
```
{{ llm_generated.subject }}
```

### Corps (généré par LLM)
```html
<!DOCTYPE html>
<html lang="fr-CH">
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            line-height: 1.7;
            color: #333;
            max-width: 580px;
            margin: 0 auto;
            padding: 20px;
        }
        a {
            color: #0066cc;
            text-decoration: none;
        }
        .signature {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
            font-size: 14px;
        }
        .unsubscribe {
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #e0e0e0;
            font-size: 12px;
            color: #999;
            text-align: center;
        }
    </style>
</head>
<body>
    {{ llm_generated.body }}

    <div class="signature">
        <strong>{{ sender.name }}</strong><br>
        {{ sender.title }}<br>
        LX Studio - Agence Web & Automatisation<br>
        📧 <a href="mailto:contact@lxstudio.ch">contact@lxstudio.ch</a><br>
        🌐 <a href="https://lxstudio.ch">lxstudio.ch</a><br>
        📅 <a href="{{ calendly_link }}">Prendre rendez-vous</a>
    </div>

    <div class="unsubscribe">
        Vous recevez cet email car votre profil correspond à notre cible.
        <a href="{{ base_url_n8n }}/webhook/lx/unsubscribe?email={{ contact.email | url_encode }}&hash={{ unsubscribe_hash }}">
            Se désabonner
        </a>
    </div>
</body>
</html>
```

---

## 6. EMAIL CONFIRMATION DÉSABONNEMENT

### Sujet
```
Confirmation de désabonnement - LX Studio
```

### Corps HTML
```html
<!DOCTYPE html>
<html lang="fr-CH">
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 500px;
            margin: 50px auto;
            padding: 20px;
            text-align: center;
        }
        .check-icon {
            font-size: 48px;
            color: #28a745;
        }
    </style>
</head>
<body>
    <div class="check-icon">✓</div>
    <h2>Désabonnement confirmé</h2>
    <p>
        Votre adresse <strong>{{ contact.email }}</strong> a été retirée
        de notre liste de prospection.
    </p>
    <p>
        Vous ne recevrez plus d'emails promotionnels de notre part.
    </p>
    <p style="font-size: 14px; color: #666; margin-top: 30px;">
        Merci de nous avoir donné l'opportunité de vous contacter.<br>
        Si c'était une erreur, contactez-nous à
        <a href="mailto:contact@lxstudio.ch">contact@lxstudio.ch</a>.
    </p>
    <p style="font-size: 12px; color: #999; margin-top: 40px;">
        LX Studio | Suisse Romande
    </p>
</body>
</html>
```

---

## PLACEHOLDERS DISPONIBLES

### Contact
- `{{ contact.first_name }}`
- `{{ contact.last_name }}`
- `{{ contact.email }}`
- `{{ contact.company }}`
- `{{ contact.phone }}`
- `{{ contact.canton }}`

### Project / Lead
- `{{ project.service_type }}`
- `{{ project.service_type_label }}`
- `{{ project.description }}`
- `{{ project.description_short }}`
- `{{ project.timeline }}`
- `{{ project.timeline_estimated }}`
- `{{ project.warranty_period }}`
- `{{ project.support_included }}`

### Pricing / Quote / Invoice
- `{{ pricing.amount_ht }}`
- `{{ pricing.amount_ttc }}`
- `{{ pricing.vat_amount }}`
- `{{ quote.quote_number }}`
- `{{ quote.accept_url }}`
- `{{ quote.expires_at }}`
- `{{ invoice.invoice_number }}`
- `{{ invoice.payment_url }}`
- `{{ invoice.due_date }}`

### System / Config
- `{{ base_url_n8n }}`
- `{{ calendly_link }}`
- `{{ unsubscribe_hash }}`
- `{{ sender.name }}`
- `{{ sender.title }}`

### Date Filters (n8n expressions)
- `{{ variable | format_date }}` → formatage date courte
- `{{ variable | format_datetime }}` → formatage date + heure
- `{{ variable | format_chf }}` → formatage montant CHF (espaces milliers)

---

**FIN DES TEMPLATES EMAIL**
