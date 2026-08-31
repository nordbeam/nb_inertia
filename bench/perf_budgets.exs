# p95 ceilings are in microseconds per operation. They are rounded from three
# local runs of the gate-shaped benchmark (40 operations, 8 samples) and leave
# several multiples of headroom for scheduler/runner variance. Keep the limits
# close enough to the measured values to catch an accidental algorithmic
# regression without treating normal CI noise as a failure.
%{
  controller_rendering: %{
    small: %{max_p95_us: 2_000, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 12_500, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 20_000, max_memory_delta_bytes: 64_000_000}
  },
  core_controller_rendering: %{
    small: %{max_p95_us: 2_000, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 3_500, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 16_000, max_memory_delta_bytes: 64_000_000}
  },
  prop_runtime_processing: %{
    small: %{max_p95_us: 100, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 750, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 750, max_memory_delta_bytes: 64_000_000}
  },
  prop_serializer_recursion: %{
    small: %{max_p95_us: 750, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 2_000, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 8_000, max_memory_delta_bytes: 64_000_000}
  },
  shared_prop_resolution: %{
    small: %{max_p95_us: 750, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 1_500, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 1_500, max_memory_delta_bytes: 64_000_000}
  },
  camelization: %{
    small: %{max_p95_us: 2_500, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 20_000, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 60_000, max_memory_delta_bytes: 64_000_000}
  },
  flash_plug_overhead: %{
    small: %{max_p95_us: 100, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 100, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 100, max_memory_delta_bytes: 64_000_000}
  },
  modal_composition: %{
    small: %{max_p95_us: 50, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 50, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 50, max_memory_delta_bytes: 64_000_000}
  },
  ssr_call_preparation: %{
    small: %{max_p95_us: 1_500, max_memory_delta_bytes: 64_000_000},
    medium: %{max_p95_us: 10_000, max_memory_delta_bytes: 64_000_000},
    large: %{max_p95_us: 35_000, max_memory_delta_bytes: 64_000_000}
  }
}
