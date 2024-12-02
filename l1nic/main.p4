#include <core.p4>
#include <pna.p4>

struct empty_metadata_t {}
struct headers_t {}

struct metadata_t {}

parser MainParserImpl(
    packet_in pkt,
    out   headers_t hdr,
    inout metadata_t umeta,
    in    pna_main_parser_input_metadata_t istd)
{
    state start {
        transition accept;
    }
}

// As of 2024-Dec-02, p4c-dpdk implementation of PNA architecture
// still requires PreControl.

control PreControlImpl(
    in    headers_t hdr,
    inout metadata_t umeta,
    in    pna_pre_input_metadata_t  istd,
    inout pna_pre_output_metadata_t ostd)
{
    apply {
    }
}

control MainDeparserImpl(
    packet_out pkt,
    in headers_t hdr,
    in metadata_t umeta,
    in pna_main_output_metadata_t ostd)
{
    apply {
        pkt.emit(hdr);
    }
}

control MainControlImpl(
    inout headers_t  hdr,
    inout metadata_t umeta,
    in    pna_main_input_metadata_t  istd,
    inout pna_main_output_metadata_t ostd)
{
    apply {
        if (istd.input_port == (PortId_t) 0) {
            send_to_port((PortId_t) 1);
        } else {
            send_to_port((PortId_t) 0);
        }
    }
}

PNA_NIC(
    MainParserImpl(),
    PreControlImpl(),
    MainControlImpl(),
    MainDeparserImpl()
    ) main;
