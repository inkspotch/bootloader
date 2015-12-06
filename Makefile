ASM=nasm

boot.img: boot.bin
	dd if=boot.bin of=boot.img bs=512 count=2880 conv=notrunc

boot.bin: bootloader.s
	$(ASM) $< -f bin -o boot.bin

.PHONY: clean
clean:
	rm -fr *.img *.bin
