Simple binary that runs 7z using different format and levels then compare results

# Result example

```
Format          Original   Compressed    Ratio   Seconds
min.zip        36.91 MB      13.66 MB     37%      0.46s
min.bzip2      36.91 MB      12.41 MB     34%      0.71s
min.lzma2      36.91 MB      10.94 MB     30%      0.42s
min.lz4        36.91 MB      18.07 MB     49%      0.20s
min.lz5        36.91 MB      22.79 MB     62%      0.21s
min.zstd       36.91 MB      14.18 MB     38%      0.21s
normal.zip     36.91 MB      12.65 MB     34%      1.63s
normal.bzip2   36.91 MB      11.85 MB     32%      0.79s
normal.lzma2   36.91 MB       6.17 MB     17%      5.05s
normal.lz4     36.91 MB      15.06 MB     41%      0.25s
normal.lz5     36.91 MB      18.03 MB     49%      0.23s
normal.zstd    36.91 MB      12.98 MB     35%      0.22s
max.zip        36.91 MB      12.42 MB     34%     12.43s
max.bzip2      36.91 MB      11.68 MB     32%      7.22s
max.lzma2      36.91 MB       5.55 MB     15%      5.89s
max.lz4        36.91 MB      14.72 MB     40%      0.49s
max.lz5        36.91 MB      14.95 MB     40%      0.51s
max.zstd       36.91 MB       6.22 MB     17%      6.55s
```

# Usage

Download the binary in releases than run on terminal: `./cac /path/to/any/folder`

> Make sure 7z is installed.

## Using dart

### Run
`dart run main.dart /path/to/any/folder`

### Compile
`dart compile exe -o cac main.dart`

`./cac /path/to/any/folder`
