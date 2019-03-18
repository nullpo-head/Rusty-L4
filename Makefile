all: run

build/kernel: build/startup build
	cargo xbuild --target x86_64-rusty_l4.json
	cp target/x86_64-rusty_l4/debug/librusty_l4.a build/
	ld -n -Tsrc/linker.ld -o build/kernel-nonstripped build/startup build/librusty_l4.a
	objcopy -g build/kernel-nonstripped build/kernel

build/startup: src/linker.ld src/startup.S build
	gcc -c -fno-pic -no-pie -nostdlib -Tlinker.ld -o build/startup -Wl,-n src/startup.S 

build/os.iso: build/kernel grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp build/kernel build/isofiles/boot/kernel.bin
	cp grub.cfg build/isofiles/boot/grub/
	grub-mkrescue -o build/os.iso build/isofiles

build:
	mkdir build

run: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso -serial stdio -cpu Haswell,+pdpe1gb -no-reboot 

clean:
	rm -rf build

.PHONY: run all clean kernel
