#!/usr/bin/env nu
# vim: ft=nu:
# Prints the search.nixos.org index version the website itself queries, cached for a day.
# nh bundles a fixed version that stops updating once the site moves on; this goes in NH_SEARCH_BACKEND_VERSION.
# Prints nothing if it was never fetched and the site can't be reached, so nh keeps its own default.

def main [] {
  let cache = $nu.cache-dir | path join nh-search-index
  let cached = if ($cache | path exists) { open --raw $cache | str trim }
  if $cached != null and ((date now) - (ls $cache | get 0.modified) < 1day) { return $cached }
  let fresh = try {
    let js = http get --max-time 5sec https://search.nixos.org/packages
    | parse --regex 'src="(?<s>/static/js/index\.[^"]+\.js)"' | get 0.s
    http get --max-time 5sec $"https://search.nixos.org($js)"
    | parse --regex 'elasticsearchMappingSchemaVersion:parseInt\("(?<v>\d+)"\)' | get 0.v
  } catch { null }
  mkdir $nu.cache-dir
  if $fresh == null {
    # offline or the site changed: keep what we had, and dated so the next try is in an hour, not on every call
    $cached | default "" | save --force $cache
    ^touch -d "23 hours ago" $cache
    return ($cached | default "")
  }
  $fresh | save --force $cache
  $fresh
}
