===============================================================================

                      ⚡ Fileboost Installation Complete!

===============================================================================

The Fileboost initializer has been created at:
config/initializers/fileboost.rb

Next steps:

1. Set your environment variables:
   export FILEBOOST_PROJECT_ID="your-project-id"
   export FILEBOOST_TOKEN="your-secret-token"

2. Or configure directly in the initializer file:
   Edit config/initializers/fileboost.rb with your credentials

3. Start using Fileboost helpers in your views:

   <!-- Replace image_tag with fileboost_image_tag -->

   <%= fileboost_image_tag user.avatar, alt: "Avatar", resize: {width: 100, height: 100, fit: "cover"} %>

   <!-- Generate optimized URLs -->

   <%= fileboost_url_for post.image %>

4. Supported transformation options:
   - width, height (or w, h)
   - quality (or q): 1-100
   - format (or f): webp, jpeg, png, gif, avif
   - blur (or b): 0-100
   - brightness (or br): 0-200
   - contrast (or c): 0-200
   - rotation (or r): 0-359
   - fit: cover, contain, fill, scale-down, crop, pad

For more information, visit: https://fileboost.dev

===============================================================================
