#!/bin/bash

sak16=12345678901234567890123456789012
sak32=1234567890123456789012345678901212345678901234567890123456789012
salt=838383838383838383838383

rm -rf /sys/fs/bpf/xdp/dispatch* 
#ip netns exec ns1 ./cpass/xdp_pass_user  --dev e12 --unload-all 2>/dev/null
#ip netns exec ns2 ./cpass/xdp_pass_user  --dev e21 --unload-all 2>/dev/null
#ip netns exec ns2 ./cpass/xdp_pass_user  --dev e23 --unload-all 2>/dev/null
#ip netns exec ns3 ./cpass/xdp_pass_user  --dev e32 --unload-all 2>/dev/null
#ip netns exec ns3 ./cpass/xdp_pass_user  --dev e34 --unload-all 2>/dev/null
#ip netns exec ns4 ./cpass/xdp_pass_user  --dev e43 --unload-all 2>/dev/null
# bridge in 1
#delete first
ip netns del ns1 2>/dev/null
ip netns del ns2 2>/dev/null
ip netns del ns3 2>/dev/null
ip netns del ns4 2>/dev/null
#ip link del br1 2>/dev/null

umount /etc/netns/ns1/bpf 2>/dev/null
umount /etc/netns/ns2/bpf 2>/dev/null
umount /etc/netns/ns3/bpf 2>/dev/null
umount /etc/netns/ns4/bpf 2>/dev/null


if [ "x$1" == "xclean" ]; then
    exit 0
fi
sleep .2

echo "begin create" 
# add intf
mkdir -p /etc/netns/ns{1,2,3,4}/bpf
mkdir -p /etc/bpf
mount --bind /sys/fs/bpf /etc/netns/ns1/bpf
mount --bind /sys/fs/bpf /etc/netns/ns2/bpf
mount --bind /sys/fs/bpf /etc/netns/ns3/bpf
mount --bind /sys/fs/bpf /etc/netns/ns4/bpf
ip netns add ns1
ip netns add ns2
ip netns add ns3
ip netns add ns4


ip link add e12 netns ns1 type veth peer name e21 netns ns2
ip link add e23 netns ns2 type veth peer name e32 netns ns3
ip link add e34 netns ns3 type veth peer name e43 netns ns4

#ip link add e1b netns ns1 type veth peer name eb1
#ip link add e2b netns ns2 type veth peer name eb2
#ip link add e3b netns ns3 type veth peer name eb3
#ip link add e4b netns ns4 type veth peer name eb4
#ip link add br1 type bridge

# set link
#ip link set br1 up
#ip link set eb1 up
#ip link set eb2 up
#ip link set eb3 up
#ip link set eb4 up
#ip link set eb1 master br1
#ip link set eb2 master br1
#ip link set eb3 master br1
#ip link set eb4 master br1

ip netns exec ns1 ip link set lo up
ip netns exec ns1 ip link set e12 up
#ip netns exec ns1 ip link set e1b up

ip netns exec ns2 ip link set lo up
ip netns exec ns2 ip link set e21 up
ip netns exec ns2 ip link set e23 up
#ip netns exec ns2 ip link set e2b up

ip netns exec ns3 ip link set lo up
ip netns exec ns3 ip link set e32 up
ip netns exec ns3 ip link set e34 up
#ip netns exec ns3 ip link set e3b up

ip netns exec ns4 ip link set lo up
ip netns exec ns4 ip link set e43 up
#ip netns exec ns4 ip link set e4b up

# bridge 11.0.0.*
# 21, 23, 32, 34 no ip, 12, 43 12.0.0.*
#ip addr add 11.0.0.1/24 dev br1
#ip netns exec ns1 ip addr add 11.0.0.11/24 dev e1b
#ip netns exec ns2 ip addr add 11.0.0.12/24 dev e2b
#ip netns exec ns3 ip addr add 11.0.0.13/24 dev e3b
#ip netns exec ns4 ip addr add 11.0.0.14/24 dev e4b

ip netns exec ns1 ip addr add 12.0.0.12/24 dev e12
ip netns exec ns2 ip addr add 12.0.0.21/24 dev e21
ip netns exec ns2 ip addr add 13.0.0.23/24 dev e23
ip netns exec ns3 ip addr add 13.0.0.32/24 dev e32
ip netns exec ns3 ip addr add 14.0.0.34/24 dev e34
ip netns exec ns4 ip addr add 14.0.0.43/24 dev e43

if [ "x$1" == "xxdp" ]; then
    ip netns exec ns1 ip route add 14.0.0.0/24 dev e12

    ip netns exec ns4 ip route add 12.0.0.0/24 dev e43

    (cd cpass; ip netns exec ns1 ./xdp_pass_user --dev e12)  &
if [ "x$2" == "xaf" ]; then
    ip netns exec ns2 ./af_go/afgo -inlink e21 -outlink e23 -inlinkqueue 0 -outlinkqueue 0 &
#    ip netns exec ns2 ./direct_pass/xpass -if e23  &
#    ip netns exec ns2 ./af_go/afgo -from e23 -to e21  &
else
    (cd cpass; ip netns exec ns2 ./xdp_pass_user --dev e21)  &
    (cd cpass; ip netns exec ns2 ./xdp_pass_user --dev e23)  &
fi

    ip netns exec ns1 bash -c "echo 0 >  /proc/sys/net/ipv4/conf/e12/rp_filter"

# for test from ns3 to ns1
#    ip netns exec ns1 ip route add 13.0.0.0/24 dev e12
    ip netns exec ns3 bash -c "echo 0 >  /proc/sys/net/ipv4/conf/e32/rp_filter"

    ip netns exec ns1 ethtool -K e12 tx off
    ip netns exec ns3 ethtool -K e32 tx off
#    ip netns exec ns3 ip route add 12.0.0.0/24 dev e32
    (cd cpass; ip netns exec ns3 ./xdp_pass_user --dev e32)  &

    ip netns exec ns1 ip route add 13.0.0.0/24 via 12.0.0.21 dev e12
    ip netns exec ns3 ip route add 12.0.0.0/24 via 13.0.0.23 dev e32
# for test from ns4 to ns1
#if [ "x$2" == "xaf" ]; then
#    ip netns exec ns3 ./af_go/afgo -inlink e32 -outlink e34 -inlinkqueue 0 -outlinkqueue 0  &
#else
#    ip netns exec ns3 ./direct_fwd/xfwd -from e32 -to e34  &
#    ip netns exec ns3 ./direct_fwd/xfwd -from e34 -to e32  &
#fi
#    ip netns exec ns4 ./direct_pass/xpass -if e43  &
#    ip netns exec ns1 ethtool -K e12 tx off
#    ip netns exec ns4 ethtool -K e43 tx off
#    ip netns exec ns4 bash -c "echo 0 >  /proc/sys/net/ipv4/conf/e43/rp_filter"

else

    ip netns exec ns1 ip route add 14.0.0.0/24 via 12.0.0.21 dev e12
    ip netns exec ns1 ip route add 13.0.0.0/24 via 12.0.0.21 dev e12

    ip netns exec ns4 ip route add 12.0.0.0/24 via 14.0.0.34 dev e43

    ip netns exec ns2 ip route add 14.0.0.0/24 via 13.0.0.32 dev e23

    ip netns exec ns3 ip route add 12.0.0.0/24 via 13.0.0.23 dev e32

    ip netns exec ns1 bash -c "echo 0 >  /proc/sys/net/ipv4/conf/e12/rp_filter"
    ip netns exec ns3 bash -c "echo 0 >  /proc/sys/net/ipv4/conf/e32/rp_filter"

fi

echo "done"
