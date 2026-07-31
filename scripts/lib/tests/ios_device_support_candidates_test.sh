result="$(printf '17.5 (21F79)\n16.2 (20C65)\n18.1 (22B83)\n17.0 (21A329)\n' | ios_device_support_candidates)"
assert_eq "$(printf '16.2 (20C65)\n17.0 (21A329)')" "$result" "excludes the 2 newest versions"

result_small="$(printf '17.5 (21F79)\n18.1 (22B83)\n' | ios_device_support_candidates)"
assert_eq "" "$result_small" "keeps everything when 2 or fewer entries"

result_empty="$(printf '' | ios_device_support_candidates)"
assert_eq "" "$result_empty" "empty input produces empty output"
