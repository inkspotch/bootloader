ASM=nasm

BUILD_DIR=./build

BOOTLOADER_SRCS := $(wildcard *.s)
BOOTLOADER_OBJS := $(patsubst %.s, $(BUILD_DIR)/%.o, $(BOOTLOADER_SRCS))

all: bootdisk

$(BUILD_DIR)/%.o: %.s
	mkdir -p  build
	$(ASM) -f bin $< -o $@

boot.img: $(BUILD_DIR)/bootloader.o
	dd if=/dev/zero of=$@ bs=1024 count=1440 
	DISK=`hdiutil attach -nomount $@`; \
	newfs_msdos -F 12 -u 18 -e 224 -f 1440 $$DISK; \
	hdiutil detach $$DISK
	dd if=$< of=$@ bs=1 count=512 conv=notrunc

bootdisk: boot.img $(BOOTLOADER_OBJS)
	hdiutil attach $<
	cp $(BUILD_DIR)/stage1_5.o "/Volumes/RPN OS/STAGE1_5.sys"
	hdiutil detach disk2

qemu: boot.img
	qemu-system-i386 -m 256 -fda $<

.PHONY: clean
clean:
	rm -fr boot.img
	rm -fr build/
