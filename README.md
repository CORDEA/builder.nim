# builder.nim

Build all packages registered in nimble.

## Usage

Requires git 2.3 or later.

```console
$ nim c builder.nim
$ ./builder --log-project:/git/project/path ~/nim/bin/path
```

## How

1. Download package.
- Download package dependencies by nimble.
- Build all nim scripts in srcDir.
- Output the result.

## Status icon

| Icon | Description |
|:---:|:---:|
| :sunny: | Success |
| :umbrella: | Compile failed |
| :zap: | Install failed |
