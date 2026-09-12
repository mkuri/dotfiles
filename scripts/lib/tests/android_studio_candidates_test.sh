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

# Preview installs carry their own version series. Sorting the full basenames
# would place every "AndroidStudioPreview..." entry after every stable one, so
# these obsolete previews would be kept and stable 2025.3.3/2025.3.4 offered
# for deletion instead.
result_preview="$(printf 'AndroidStudio2025.3.3\nAndroidStudio2026.1.2\nAndroidStudioPreview2021.1\nAndroidStudioPreview2022.1\nAndroidStudio2025.3.4\n' | android_studio_candidates)"
assert_eq "" "$result_preview" "keeps 3 per channel when stable and preview coexist"

# Each channel is pruned against its own 3-generation budget.
result_preview_mixed="$(printf 'AndroidStudio2025.3.3\nAndroidStudio2025.3.4\nAndroidStudio2026.1.2\nAndroidStudio2026.1.3\nAndroidStudioPreview2024.1\nAndroidStudioPreview2024.2\nAndroidStudioPreview2024.3\nAndroidStudioPreview2025.1\n' | android_studio_candidates)"
assert_eq "$(printf 'AndroidStudio2025.3.3\nAndroidStudioPreview2024.1')" "$result_preview_mixed" "prunes stable and preview independently"
