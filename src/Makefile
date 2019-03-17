all: run

kernel.bin: startup
	cargo xbuild --target ../x86_64-rusty_l4.json
	cp ../target/x86_64-rusty_l4/debug/librusty_l4.a ./
	ld -n -Tlinker.ld -o kernel.bin startup librusty_l4.a
	objcopy -g kernel.bin kernel.bin

startup: linker.ld startup.S
	gcc -c -fno-pic -no-pie -nostdlib -Tlinker.ld -o startup -Wl,-n startup.S 

os.iso: kernel.bin grub.cfg
	mkdir -p isofiles/boot/grub
	cp kernel.bin isofiles/boot/kernel.bin
	cp grub.cfg isofiles/boot/grub/
	grub-mkrescue -o os.iso isofiles

run: os.iso
	qemu-system-x86_64 -cdrom os.iso -serial stdio -cpu Haswell,+pdpe1gb -no-reboot 

clean:
	rm -rf kernel.bin os.iso isofiles

.PHONY: run all clean
