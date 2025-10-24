# `ascii`

An ASCII lookup command-line-interface.

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
./out/ascii a
```

```
65
```

---

## 📄 License

This project is licensed under the [MIT License](./LICENSE). See [LICENSE](./LICENSE) file for more details.
