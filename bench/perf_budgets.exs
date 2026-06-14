%{
  controller_rendering: %{
    small: %{max_p95_us: 150_000, max_memory_delta_bytes: 64_000_000}
  },
  core_controller_rendering: %{
    small: %{max_p95_us: 150_000, max_memory_delta_bytes: 64_000_000}
  },
  prop_runtime_processing: %{
    small: %{max_p95_us: 75_000, max_memory_delta_bytes: 64_000_000}
  },
  prop_serializer_recursion: %{
    small: %{max_p95_us: 75_000, max_memory_delta_bytes: 64_000_000}
  },
  shared_prop_resolution: %{
    small: %{max_p95_us: 75_000, max_memory_delta_bytes: 64_000_000}
  },
  camelization: %{
    small: %{max_p95_us: 150_000, max_memory_delta_bytes: 64_000_000}
  },
  flash_plug_overhead: %{
    small: %{max_p95_us: 75_000, max_memory_delta_bytes: 64_000_000}
  },
  modal_composition: %{
    small: %{max_p95_us: 75_000, max_memory_delta_bytes: 64_000_000}
  },
  ssr_call_preparation: %{
    small: %{max_p95_us: 75_000, max_memory_delta_bytes: 64_000_000}
  }
}
