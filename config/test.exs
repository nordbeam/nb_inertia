import Config

# Configure a minimal test endpoint for nb_inertia
config :nb_inertia,
  endpoint: NbInertia.TestEndpoint

# Configure Phoenix for testing
config :phoenix, :json_library, Jason
