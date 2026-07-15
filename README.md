# `ascii`

An ASCII lookup command-line-interface and web reference.

**American Standard Code for Information Interchange (ASCII)** is a character-encoding standard that assigns a unique number rainging from 0 to 127 to letters, digits, and symbols. For example, uppercase 'A' is represented by the decimal `65` (or `1000001` in binary). It is a 7-bit encoding system based on the English alphabet representing upto 128 characters.

In digital communication, computers process information in binary code (`0`s and `1`s). ASCII values serve as a bridge between human-readable text and computer-readable binary code. It includes:

- **control characters**: 0-31 and 127
    - `NUL` (Null Character): 0
    - `LF` (Line Feed): 10
    - `DEL` (Delete) 127
- **printable characters**: 32-126
    - `A` (Uppercase A): 65
    - `B` (Uppercase B): 66
    - `a` (Lowercase a): 97
    - ` ` (Space): 32
    - `5` (Number 5): 53
    - `7` (Number 7): 55
    - `!` (Exclamation Mark): 33

---

## Usage

Run the executable followed by one or more values:

```sh
$ ./ascii S
S    83 0x53 0o123 0b1010011
```

```sh
$ ./ascii A B C
A    65 0x41 0o101 0b1000001
B    66 0x42 0o102 0b1000010
C    67 0x43 0o103 0b1000011
```

```sh
$ ./ascii Hello --hex
0x48 0x65 0x6C 0x6C 0x6F
```

### Help

```
Usage: ascii <value> [value ...] | [flag]

Display ASCII information for one or more values.

Values can be:
  Characters:        A   Hello   (each character is processed individually)
  Numeric (--lookup): 65   0x41   0o101   0b1000001

Flags:
  -f, --full        Display the full ASCII table.
  -h, --help        Display this help message.
  -d, --dec         Show decimal representation
  -x, --hex         Show hexadecimal representation
  -o, --oct         Show octal representation
  -b, --bin         Show binary representation
  -c, --char        Show character glyph
  -l, --lookup      Treat values as numeric codes

Examples:
  ascii A               Show all representations of 'A'
  ascii Hello           Process each character in 'Hello'
  ascii A B --hex       Show hex only for 'A' and 'B'
  ascii Hello --hex     Show hex for each byte in 'Hello'
  ascii --lookup 65     Look up decimal code 65
  ascii -l 0x41 --char  Look up hex 0x41, show glyph only
```

---

## Web

An interactive ASCII reference webpage is available at **[shresht7.github.io/ascii](https://shresht7.github.io/ascii)**.

- **Search**: find any character or code (decimal, hex, octal, binary). Prefix with `0x`, `0o`, or `0b` for targeted searches.
- **Converter**: type a multi-character string to see each character's `glyph`, `DEC`, `HEX`, `OCT`, and `BIN` values.
- **Copy**: click any table cell to copy its value; click a converter row to copy the entire line.
- **Keyboard shortcuts**: press `/` to focus the search, `Esc` to clear and blur.

---

<!-- Lore: 86th Repository on my GitHub -->

## 📦 Development

Written in `x86_64` Assembly for Linux.

### Requirements

- `nasm`: compiler

### Compilation

```sh
nasm -f elf64 ./src/ascii.asm -o ./obj/ascii.o
```

### Linking

```sh
ld ./obj/ascii.o -o ./out/ascii
```

### Execution

```sh
./out/ascii A
```

```
A    65 0x41 0o101 0b1000001
```

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE). See [LICENSE](./LICENSE) file for more details.
