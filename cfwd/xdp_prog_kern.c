/* SPDX-License-Identifier: GPL-2.0 */
#include <linux/bpf.h>
#include <linux/in.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

// The parsing helper functions from the packet01 lesson have moved here
#include "../common/parsing_helpers.h"
#include "../common/rewrite_helpers.h"

/* Defines xdp_stats_map */
#include "../common/xdp_stats_kern_user.h"
#include "../common/xdp_stats_kern.h"

#ifndef memcpy
#define memcpy(dest, src, n) __builtin_memcpy((dest), (src), (n))
#endif

struct {
	__uint(type, BPF_MAP_TYPE_DEVMAP);
	__uint(key_size, sizeof(int));
	__uint(value_size, sizeof(int));
	__uint(max_entries, 4);
	__uint(pinning, LIBBPF_PIN_BY_NAME);
} xdp_tx_ports SEC(".maps");


SEC("xdp_fwd_direct")
int xdp_fwd_direct_prog(struct xdp_md *ctx)
{
    int key = ctx->ingress_ifindex;
    int *value;
    value = bpf_map_lookup_elem(&xdp_tx_ports, &key);
    if (value) {
//        bpf_trace_printk("map of key is %d\n", sizeof("map of key is %d\n"), *value);
    } else {
        bpf_trace_printk("failed get key\n", sizeof("failed get key\n"));
        return XDP_PASS;
    }
//    bpf_trace_printk("fwd got pkt %d\n", sizeof("fwd got pkt %d\n"), ctx->ingress_ifindex);
    return bpf_redirect_map(&xdp_tx_ports, ctx->ingress_ifindex, 0);
}
char _license[] SEC("license") = "GPL";
