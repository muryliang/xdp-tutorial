#note:
# BFP_DIR_MNT is set in libxdp and libbpf building
# run make with this below, then see setupnet.sh for ip netns setup for bpf pin
make clean
BPF_DIR_MNT=/etc/bpf make
