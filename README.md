# cianOS

cianOS is an x86-64-bit operating system written in C. 

The purpose of cianOS is to learn low-level OS programming and to create a fully working OS with basic functionality. 

## Requirements

On Ubuntu:
```
sudo apt install grub2 nasm xorriso mtools qemu-system
```

To run cianOS:
```
# compile all files necessary to create the .iso file
make all
# run qemu emulator with the compiled .iso file
make run
```
