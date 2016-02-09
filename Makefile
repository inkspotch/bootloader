ASM=nasm

boot.img: boot.bin
	dd if=/dev/zero of=$@ bs=1024 count=1440 
	DISK=`hdiutil attach -nomount $@`; \
	newfs_msdos -F 12 -u 18 -e 224 -f 1440 $$DISK; \
	hdiutil detach $$DISK
	dd if=$< of=$@ bs=1 count=512 conv=notrunc

write_file: boot.img stage2.sys
	hdiutil attach $<
	#echo 'HELLO' >> "/Volumes/RPN OS/STAGE2.sys"
	cp stage2.sys "/Volumes/RPN OS/STAGE2.sys"
	hdiutil detach /dev/disk3

stage2.sys: stage2.s
	$(ASM) $< -f bin -o $@

boot.bin: bootloader.s
	$(ASM) $< -f bin -o boot.bin

qemu: boot.img
	qemu-system-i386 -m 256 -hda $<

.PHONY: clean
clean:
	rm -fr *.img *.bin
