# Changelog

## [0.1.0] - 2025-03-08

- Initial release:
- Traduzione di file YAML da una lingua sorgente verso una o più lingue target.
- Configurazione centralizzata tramite initializer, con impostazioni per API keys, lingua sorgente, lingue target, output folder, esclusioni e modalità di traduzione (override/incremental).
- Supporto per provider multipli: ChatGPT (OpenAI) e Google Gemini.
- Monitoraggio del progresso della traduzione tramite ruby-progressbar.
- Funzionalità di merge incrementale per aggiornare solo le chiavi mancanti nei file tradotti.
