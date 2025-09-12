# Fileboost

[![Gem Version](https://badge.fury.io/rb/fileboost.svg)](https://badge.fury.io/rb/fileboost)

Fileboost is a Rails gem that provides seamless integration with the Fileboost.dev image optimization service. It offers drop-in replacement helpers for Rails' native image helpers with automatic optimization, HMAC authentication, and comprehensive transformation support for ActiveStorage objects.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Drop-in Replacement (Recommended)](#drop-in-replacement-recommended)
  - [Manual Helper Method](#manual-helper-method)
  - [URL Generation](#url-generation)
  - [Transformation Options](#transformation-options)
  - [Parameter Aliases](#parameter-aliases)
  - [ActiveStorage Support](#activestorage-support)
  - [ActiveStorage Variants (NEW in v0.2.0)](#activestorage-variants-new-in-v020)
    - [Variant Transformation Mapping](#variant-transformation-mapping)
    - [Combining Variants with Custom Options](#combining-variants-with-custom-options)
  - [Responsive Images](#responsive-images)
- [Error Handling](#error-handling)
- [Security](#security)
- [Development](#development)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Features

- 🚀 **Drop-in replacement** for Rails `image_tag` with zero code changes (NEW in v0.2.0)
- 🎨 **Full ActiveStorage Variant support** with automatic transformation mapping (NEW in v0.2.0)
- 🔒 **Secure HMAC authentication** with Fileboost.dev service
- 📱 **ActiveStorage only** - works exclusively with ActiveStorage attachments
- 🎛️ **Comprehensive transformations** - resize, quality, format conversion, and more
- 🔧 **Simple configuration** - just project ID and token required
- 🔄 **Automatic fallback** - non-ActiveStorage images work exactly as before

## Requirements

- Ruby 3.0+
- Rails 7.1+
- ActiveStorage

## Installation

Register an account at [Fileboost.dev](https://fileboost.dev) and obtain your project ID and token.

Add this line to your application's Gemfile:

```ruby
gem "fileboost"
```

And then execute:

```bash
$ bundle install
```

Generate the initializer:

```bash
$ rails generate fileboost:install
```

## Configuration

Set your environment variables:

```bash
export FILEBOOST_PROJECT_ID="your-project-id"
export FILEBOOST_TOKEN="your-secret-token"
```

Or configure directly in your initializer:

```ruby
# config/initializers/fileboost.rb
Fileboost.configure do |config|
  config.project_id = ENV["FILEBOOST_PROJECT_ID"]
  config.token = ENV["FILEBOOST_TOKEN"]
  
  # Optional: Enable drop-in replacement for Rails image_tag (default: false)
  config.patch_image_tag = true
end
```

## Usage

### Drop-in Replacement (Recommended)

Enable `patch_image_tag` in your configuration to automatically optimize ActiveStorage images with your existing `image_tag` calls:

```ruby
# config/initializers/fileboost.rb
Fileboost.configure do |config|
  config.project_id = ENV["FILEBOOST_PROJECT_ID"]
  config.token = ENV["FILEBOOST_TOKEN"]
  config.patch_image_tag = true  # Enable automatic optimization
end
```

With this enabled, your existing Rails code automatically gets Fileboost optimization:

```erb
<!-- This now automatically uses Fileboost for ActiveStorage objects -->
<%= image_tag user.avatar, resize: { w: 300, h: 300 }, alt: "Avatar" %>
<%= image_tag post.featured_image, resize: { width: 800, quality: 85 }, class: "hero" %>

<!-- ActiveStorage variants work seamlessly -->
<%= image_tag user.avatar.variant(resize_to_limit: [100, 100]), alt: "Thumbnail" %>
<%= image_tag post.image.variant(:thumb), alt: "Post thumbnail" %>

<!-- Non-ActiveStorage images work exactly as before -->
<%= image_tag "/assets/logo.png", alt: "Logo" %>
<%= image_tag "https://example.com/image.jpg", alt: "External" %>
```

**Benefits:**
- Zero code changes required for existing ActiveStorage images
- Full ActiveStorage variant support with automatic transformation mapping
- Automatic fallback to Rails behavior for non-ActiveStorage assets
- Gradual migration path - enable/disable with single configuration option

### Manual Helper Method

Alternatively, use `fileboost_image_tag` explicitly for ActiveStorage objects:

```erb
<!-- Before (Rails) -->
<%= image_tag user.avatar, width: 300, height: 300, alt: "Avatar" %>

<!-- After (Fileboost) -->
<%= fileboost_image_tag user.avatar, resize: { w: 300, h: 300 }, alt: "Avatar" %>
```

**Note:** Fileboost only works with ActiveStorage objects. String paths and external URLs are not supported.

### URL Generation

Generate optimized URLs directly:

```erb
<div style="background-image: url(<%= fileboost_url_for(banner.image, resize: { w: 1200, h: 400 }) %>)">
  <!-- content -->
</div>
```

### Transformation Options

Fileboost supports comprehensive image transformations:

```erb
<%= fileboost_image_tag post.image,
      resize: {
        width: 800,         # Resize width
        height: 600,        # Resize height
        quality: 85,        # JPEG/WebP quality (1-100)
        blur: 5,            # Blur effect (0-100)
        brightness: 110,    # Brightness adjustment (0-200, 100 = normal)
        contrast: 120,      # Contrast adjustment (0-200, 100 = normal)
        rotation: 90,       # Rotation in degrees (0-359)
        fit: :cover         # Resize behavior (cover, contain, fill, scale-down, crop, pad)
      },
      class: "hero-image",  # Standard Rails options work too
      alt: "Hero image" %>

<!-- Short parameter names also work -->
<%= fileboost_image_tag post.image,
      resize: { w: 800, h: 600, q: 85 },
      class: "hero-image" %>
```

### Parameter Aliases

Use short or long parameter names within the resize parameter:

```ruby
# These are equivalent:
fileboost_image_tag(image, resize: { w: 400, h: 300, q: 85 })
fileboost_image_tag(image, resize: { width: 400, height: 300, quality: 85 })
```

**🎯 Smart Optimization:** Fileboost's CDN automatically detects and delivers the optimal image format (WebP, AVIF, JPEG, etc.) based on browser capabilities, device type, and connection speed for maximum performance.

### ActiveStorage Support

Works seamlessly with all ActiveStorage attachment types:

```erb
<!-- has_one_attached -->
<%= fileboost_image_tag user.avatar, resize: { w: 150, h: 150, fit: :cover } %>

<!-- has_many_attached -->
<% post.images.each do |image| %>
  <%= fileboost_image_tag image, resize: { width: 400, quality: 90 } %>
<% end %>

<!-- Direct blob access -->
<%= fileboost_image_tag post.featured_image.blob, resize: { w: 800 } %>
```

### ActiveStorage Variants (NEW in v0.2.0)

Fileboost now provides full support for ActiveStorage variants with automatic transformation mapping:

```erb
<!-- Basic variants with automatic transformation mapping -->
<%= image_tag user.avatar.variant(resize_to_limit: [200, 200]) %>
<!-- ↓ Automatically becomes: w=200&h=200&fit=scale-down -->

<%= image_tag post.image.variant(resize_to_fit: [400, 300]) %>
<!-- ↓ Automatically becomes: w=400&h=300&fit=contain -->

<%= image_tag hero.banner.variant(resize_to_fill: [800, 400]) %>
<!-- ↓ Automatically becomes: w=800&h=400&fit=cover -->

<!-- Complex variants with multiple transformations -->
<%= image_tag post.image.variant(
  resize_to_limit: [600, 400],
  quality: 85
) %>
<!-- ↓ Automatically becomes: w=600&h=400&fit=scale-down&q=85 -->

<!-- Named variants work seamlessly -->
<%= image_tag user.avatar.variant(:thumb) %>
<!-- ↓ Uses predefined variant transformations -->
```

#### Variant Transformation Mapping

Fileboost automatically maps ActiveStorage variant transformations to optimized URL parameters:

| ActiveStorage Variant | Fileboost Parameters | Description |
|----------------------|---------------------|-------------|
| `resize_to_limit: [w, h]` | `w=W&h=H&fit=scale-down` | Resize within bounds, preserving aspect ratio |
| `resize_to_fit: [w, h]` | `w=W&h=H&fit=contain` | Resize to fit exactly, with letterboxing if needed |
| `resize_to_fill: [w, h]` | `w=W&h=H&fit=cover` | Resize and crop to fill exactly |
| `resize_and_pad: [w, h]` | `w=W&h=H&fit=pad` | Resize with padding |
| `quality: 85` | `q=85` | JPEG/WebP quality (1-100) |
| `rotate: "-90"` | `r=-90` | Rotation in degrees |


#### Combining Variants with Custom Options

You can combine variant transformations with additional Fileboost options:

```erb
<!-- Variant transformations + additional options -->
<%= image_tag user.avatar.variant(resize_to_limit: [200, 200]), 
    resize: { blur: 5, brightness: 110 } %>
<!-- ↓ Combines variant params with additional blur and brightness -->

<!-- Override variant parameters -->
<%= image_tag post.image.variant(resize_to_limit: [400, 300]),
    resize: { w: 500 } %>  
<!-- ↓ Uses h=300&fit=scale-down from variant, but overrides width to 500 -->
```

### Responsive Images

Generate multiple sizes for responsive designs:

```ruby
# In your controller or helper
@responsive_urls = fileboost_responsive_urls(hero.image, [
  { width: 400, suffix: "sm" },
  { width: 800, suffix: "md" },
  { width: 1200, suffix: "lg" }
], resize: { quality: 85 })

# Returns: { "sm" => "url1", "md" => "url2", "lg" => "url3" }
```

```erb
<!-- In your view -->
<img src="<%= @responsive_urls['md'] %>"
     srcset="<%= @responsive_urls['sm'] %> 400w,
             <%= @responsive_urls['md'] %> 800w,
             <%= @responsive_urls['lg'] %> 1200w"
     sizes="(max-width: 400px) 400px, (max-width: 800px) 800px, 1200px"
     alt="Responsive image">
```

## Error Handling

Fileboost handles errors gracefully:

- **Configuration errors**: Logs warnings about missing configuration and returns empty strings/nil
- **Invalid assets**: Logs errors when non-ActiveStorage objects are passed and returns empty strings/nil
- **Signature errors**: Returns nil when HMAC generation fails

## Security

Fileboost uses HMAC-SHA256 signatures to secure your image transformations:

- URLs are signed with your secret token
- Prevents unauthorized image manipulation
- Signatures include all transformation parameters
- Uses secure comparison to prevent timing attacks

## Development

After checking out the repo, run:

```bash
$ bundle install
$ bundle exec rspec
```

To test against the dummy Rails application:

```bash
$ cd test/dummy
$ rails server
```

## Testing

Run the test suite:

```bash
$ bundle exec rspec
```

Run RuboCop:

```bash
$ bundle exec rubocop
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`rake test`)
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- [GitHub Issues](https://github.com/Fileboost/fileboost-ruby/issues)
- [Documentation](https://github.com/Fileboost/fileboost-ruby/wiki)
