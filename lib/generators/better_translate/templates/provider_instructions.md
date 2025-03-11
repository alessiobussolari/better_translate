# Custom Provider Setup Instructions

Congratulations! You've successfully created a custom translation provider for BetterTranslate.

## Next Steps

1. **Implement the API Call**
   Open the generated file `app/providers/<%= file_name %>_provider.rb` and implement the `translate_text` method with your API-specific code.

2. **Configure Your API Key**
   Add your API key to your environment variables or credentials:
   ```ruby
   # config/credentials.yml.enc
   <%= class_name.downcase %>_api_key: your_api_key_here
   ```

3. **Update BetterTranslate Configuration**
   Add your custom provider to the BetterTranslate configuration:
   ```ruby
   # config/initializers/better_translate.rb
   BetterTranslate.configure do |config|
     # Add a new provider option
     config.provider = :<%= class_name.downcase %>
     
     # Add your API key
     config.<%= class_name.downcase %>_key = Rails.application.credentials.<%= class_name.downcase %>_api_key
     
     # ... other configuration options
   end
   ```

4. **Register Your Provider**
   Create an initializer to register your custom provider:
   ```ruby
   # config/initializers/better_translate_providers.rb
   # Require the provider file to ensure it's loaded
   require Rails.root.join('app', 'providers', '<%= file_name %>_provider')
   
   BetterTranslate::Service.register_provider(
     :<%= class_name.downcase %>,
     ->(api_key) { Providers::<%= provider_class_name %>.new(api_key) }
   )
   ```
   
   Note: The `require` statement is important to ensure the provider class is loaded before it's used.

5. **Test Your Provider**
   Try translating some text with your new provider:
   ```ruby
   BetterTranslate.configure do |config|
     config.provider = :<%= class_name.downcase %>
   end
   
   BetterTranslate.magic
   ```

## Example Usage

```ruby
# Direct usage of your provider
provider = Providers::<%= provider_class_name %>.new(api_key)
translated_text = provider.translate("Hello world", "fr", "French")
```

## Need Help?

Check out the BetterTranslate documentation for more information on how to implement and use custom providers.
