# diff_match_patch

```
diff = DiffMatchPatch.new
a = "ニホンゴ"
b = "ニホン"
d = diff.diff_main(a, b)
p diff.diff_prettyHtml(d)
```