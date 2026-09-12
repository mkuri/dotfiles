result="$(printf 'AndroidStudio2025.3.1\nAndroidStudio2026.1.2\nAndroidStudio2025.2.2\nAndroidStudio2025.3.4\nAndroidStudio2025.3.3\n' | android_studio_candidates)"
assert_eq "$(printf 'AndroidStudio2025.2.2\nAndroidStudio2025.3.1')" "$result" "excludes the 3 newest generations"

result_small="$(printf 'AndroidStudio2025.3.4\nAndroidStudio2026.1.2\nAndroidStudio2025.3.3\n' | android_studio_candidates)"
assert_eq "" "$result_small" "keeps everything when 3 or fewer generations"

result_empty="$(printf '' | android_studio_candidates)"
assert_eq "" "$result_empty" "empty input produces empty output"

# Version-aware ordering: a plain lexical sort would rank "2025.3.10" before
# "2025.3.4" and delete the wrong generation.
result_double_digit="$(printf 'AndroidStudio2025.3.4\nAndroidStudio2025.3.10\nAndroidStudio2025.3.2\nAndroidStudio2025.3.3\n' | android_studio_candidates)"
assert_eq "AndroidStudio2025.3.2" "$result_double_digit" "sorts double-digit patch numbers numerically"
