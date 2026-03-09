require_relative "lib/octo_stripe_gateway/version"

Gem::Specification.new do |spec|
  spec.name        = "octo_stripe_gateway"
  spec.version     = OctoStripeGateway::VERSION
  spec.authors     = ["Stefanija-Trpkovska"]
  spec.email       = ["stefanijatrpkovska@outlook.com"]
  spec.homepage    = "https://github.com/stefanija-trpkovska/octo_stripe_gateway"
  spec.summary     = "OCTo-compliant Stripe payment gateway for Rails"
  spec.description = "Rails engine providing Stripe payment API for SPAs"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "stripe"
end
