# Changelog

## [0.3.0] - 2025-03-11

- Added helper method `translate_texts_to_languages` to translate an array of texts.
  - This method builds on the existing `translate_text_to_languages` helper.
  - It accepts an array of texts, target languages, the source language, and the provider.
  - It returns a hash where each key is a target language code and the value is an array of translated texts.


## [0.2.0] - 2025-03-11

- Divided the filtering process into two steps:
  - **Global Exclusions**: Removes keys defined in `global_exclusions` from the entire YAML structure.
  - **Language-Specific Exclusions**: Applies further filtering using the `exclusions_per_language` map for each target language.
- This change ensures that exclusions specific to a target language (e.g., `"sample.valid"` for Italian) are applied only when translating that language, without affecting the overall global filtering.

## [0.1.1] - 2025-03-10

- Added a new Rails generator `rails generate better_translate:translate` that triggers the translation process.
    - The generator executes the translation method (e.g., `BetterTranslate.magic`) and displays progress messages.

## [0.1.0] - 2025-03-10

- Initial release:
- Traduzione di file YAML da una lingua sorgente verso una o più lingue target.
- Configurazione centralizzata tramite initializer, con impostazioni per API keys, lingua sorgente, lingue target, output folder, esclusioni e modalità di traduzione (override/incremental).
- Supporto per provider multipli: ChatGPT (OpenAI) e Google Gemini.
- Monitoraggio del progresso della traduzione tramite ruby-progressbar.
- Funzionalità di merge incrementale per aggiornare solo le chiavi mancanti nei file tradotti.
