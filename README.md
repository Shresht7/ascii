# `ascii`

An ASCII lookup command-line-interface.

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

Run the executable followed by the character you wish to see the encoding of:

```sh
./ascii S
```

```sh
83 0x53 0o123 0b1010011
```

> **Note**
>
> The tool only considers the first character of the argument.

### Flags

All flags must be passed immediately after the executable name.

```sh
./ascii -h  # For help message
./ascii -f  # Full ASCII Table
```

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
65 0x41 0o101 0b1000001
```

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE). See [LICENSE](./LICENSE) file for more details.
