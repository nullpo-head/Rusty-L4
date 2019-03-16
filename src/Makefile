all: run

kernel.bin: linker.ld startup.S
	gcc -fno-pic -no-pie -nostdlib -Tlinker.ld -o kernel.bin -Wl,-n startup.S

os.iso: isofiles isofiles/boot/kernel.bin isofiles/boot/grub/grub.cfg
	grub-mkrescue -o os.iso isofiles

isofiles:
	mkdir -p isofiles/boot/grub

isofiles/boot/kernel.bin: kernel.bin
	cp kernel.bin isofiles/boot/kernel.bin

isofiles/boot/grub/grub.cfg: grub.cfg
	cp grub.cfg isofiles/boot/grub/

run: os.iso
	qemu-system-x86_64 -cdrom os.iso -serial stdio -cpu Haswell,+pdpe1gb -no-reboot 

clean:
	rm -rf kernel.bin os.iso isofiles

.PHONY: run all clean
